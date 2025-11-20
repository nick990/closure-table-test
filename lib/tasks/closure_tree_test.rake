require "benchmark"

class BenchmarkResult
  attr_reader :node, :root_time, :self_and_descendants_time, :self_and_ancestors_time

  def initialize(node)
    @node = node
    @root_time = Benchmark.measure { node.root }.real*1000
    @self_and_descendants_time = Benchmark.measure { node.self_and_descendants }.real*1000
    @self_and_ancestors_time = Benchmark.measure { node.self_and_ancestors }.real*1000
  end

  def to_s
    s="Nodo: #{node.name} (ID: #{node.id}, Depth: #{node.depth})\n"
    s+="\tTempo per trovare la root: #{root_time.round(3)} ms\n"
    s+="\tTempo per trovare i discendenti: #{self_and_descendants_time.round(3)} ms\n"
    s+="\tTempo per trovare i predecessori: #{self_and_ancestors_time.round(3)} ms"
    s
  end
end

namespace :closure_tree do
  desc "Testa la gemma closure_tree creando un albero e verificando i metodi di navigazione con misurazione dei tempi"
  task test: :environment do
    def print_tree(node, level = 0, is_last = true, prefix = "")
      if level == 0
        puts node.name
      else
        puts prefix + "└─ #{node.name}"
      end

      children = node.children.to_a
      children.each_with_index do |child, index|
        is_last_child = index == children.size - 1
        child_prefix = if level == 0
          ""
        elsif is_last
          prefix + "   "
        else
          prefix + "|  "
        end
        print_tree(child, level + 1, is_last_child, child_prefix)
      end
    end

    def create_tree(nodes_number, generations)
      if nodes_number < generations + 1
        raise ArgumentError, "Il numero di nodi (#{nodes_number}) deve essere almeno #{generations + 1} per creare #{generations} generazioni"
      end
      index=1
      puts "#{index}/#{nodes_number}"
      root = Node.create!(name: "n#{index}")
      index += 1
      last_node=root
      flat_tree=[]
      flat_tree << root
      # Creo i nodi minimi per ogni generazione
      (generations).times do |i|
        if index%100==0 || index==nodes_number
          puts "#{index}/#{nodes_number}"
        end
        new_node = Node.create!(name: "n#{index}")
        last_node.children << new_node
        last_node = new_node
        index += 1
        if new_node.depth < generations
          flat_tree << new_node
        end
      end
      remaining_nodes=nodes_number-(generations+1)
      remaining_nodes.times do |i|
        if index%100==0 || index==nodes_number
          puts "#{index}/#{nodes_number}"
        end
        new_node = Node.create!(name: "n#{index}")
        random_node = flat_tree.sample
        random_node.children << new_node
        index += 1
        if new_node.depth < generations
          flat_tree << new_node
        end
      end
      root.reload
      root
    end

    def print_node(node)
      puts "="*80
      puts "NODE\t#{node.name}"
      puts "="*80
      puts "ID: #{node.id}"
      puts "Depth: #{node.depth}"
      puts "Root: #{node.root.name}"
      puts "Parent: #{node.parent.nil? ? 'nil' : node.parent.name}"
      puts "Children: [ #{node.children.map(&:name).join(', ')} ]"
      puts "Ancestors: [ #{node.ancestors.map(&:name).join(', ')} ]"
      puts "Descendants: [ #{node.descendants.map(&:name).join(', ')} ]"
      puts "Siblings: [ #{node.siblings.map(&:name).join(', ')} ]"
      puts "Subtree:"
      print_tree(node)
      puts "="*80
    end

    def print_benchmark_stats(title, metric, benchmark_results)
      puts "\n" + "="*80
      puts "BENCHMARK: #{title}"
      puts "="*80
      res_min = benchmark_results.min_by { |r| r.send(metric) }
      puts "Tempo minimo: #{res_min.send(metric).round(3)} ms\n\tNodo: #{res_min.node.name} (Depth: #{res_min.node.depth})"
      res_max = benchmark_results.max_by { |r| r.send(metric) }
      puts "Tempo massimo: #{res_max.send(metric).round(3)} ms\n\tNodo: #{res_max.node.name} (Depth: #{res_max.node.depth})"
      puts "Tempo medio:  #{(benchmark_results.map { |r| r.send(metric) }.sum / benchmark_results.size).round(3)} ms"
      puts "="*80
    end

    puts "\n" + "="*80
    puts "TEST CLOSURE_TREE"
    puts "="*80 + "\n"

    puts "Cancello tutti i nodi..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE node_hierarchies, nodes RESTART IDENTITY CASCADE")
    puts "✓ Tutti i nodi cancellati"


    nodes_number=500
    generations=20
    puts "Creo l'albero con #{nodes_number} nodi e #{generations} generazioni..."
    @root = create_tree(nodes_number, generations)
    puts "✓ Albero creato con successo:"
    print_tree(@root)

    puts "Nodo più profondo:"
    deepest_node = @root.descendants.max_by(&:depth)
    print_node(deepest_node)
    puts "Benchmark per il nodo più profondo:"
    deepest_node_benchmark_result = BenchmarkResult.new(deepest_node)
    puts deepest_node_benchmark_result
    puts "-"*80

    puts "Calcolo i benchmark per tutti i nodi..."
    benchmark_results = []
    @root.self_and_descendants.each_with_index do |node, index|
      benchmark_results << BenchmarkResult.new(node)
    end
    puts "✓ Benchmark calcolati con successo"

    print_benchmark_stats("Tempi di ricerca root per tutti i nodi", :root_time, benchmark_results)
    print_benchmark_stats("Tempi di ricerca discendenti per tutti i nodi", :self_and_descendants_time, benchmark_results)
    print_benchmark_stats("Tempi di ricerca predecessori per tutti i nodi", :self_and_ancestors_time, benchmark_results)
  end
end
