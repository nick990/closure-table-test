require "gruff"
require "benchmark"
require_relative "../benchmark/benchmark_result"
require_relative "../benchmark/benchmark_results_aggregate"
require_relative "../benchmark/benchmark_creation_result"

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

## Plots the creation results as a line chart
# x axis: closure table size
# y axis: creation time
def plot_creation_results(results)
  chart = Gruff::Line.new(1200)
  max_closure_table_size = results.map(&:closure_table_size).max
  max_nodes_number = results.map(&:nodes_number).max
  chart.title = "Creation Time\nClosure Table Size: #{max_closure_table_size}\nNodes Number: #{max_nodes_number}"
  chart.dot_radius = 1
  chart.data(:creation_time, results.map(&:creation_time))
  chart.title_font_size = 16
  chart.legend_font_size = 16
  chart.marker_font_size = 12
  # Show only 10 labels on the x axis

  total = results.length
  count = 10
  step  = (total - 1) / (count - 1)

  labels = {}
  (count - 1).times do |i|
    idx = (i * step).floor
    labels[idx] = results[idx].closure_table_size.to_s
  end
  labels[total - 1] = results.last.closure_table_size.to_s

  chart.labels = labels

  # Show stats in the legend
  min_time = results.map(&:creation_time).min.round(3)
  max_time = results.map(&:creation_time).max.round(3)
  average_time = (results.map(&:creation_time).sum / results.length).round(3)
  # Serie fittizie per legenda (un solo punto, colore trasparente)
  transparent = "rgba(0,0,0,0)"

  chart.data("Min: #{min_time}",   [ nil ])
  chart.data("Max: #{max_time}",   [ nil ])
  chart.data("AVG: #{average_time}", [ nil ])

# Colori: primo reale, gli altri invisibili
chart.colors = [
  "#0077cc",   # Valori
  transparent, # Min
  transparent, # Max
  transparent  # Media
]

  chart.y_axis_label = "Creation Time (ms)"
  chart.x_axis_label = "Closure Table Size"
  chart.write("plot.png")
  system("open plot.png")
  puts "✓ Plot saved to plot.png"
end

namespace :closure_tree do
  desc "Test the closure_tree gem by creating a tree and verifying the navigation methods with timing measurements. Parameters: nodes_number (default: 50), generations (default: 4)"
  task test: :environment do
    def csv_header
      [
        "nodes_number",
        "generations",
        "closure_table_size",
        "root_avg_ms",
        "root_min_ms",
        "root_max_ms",
        "self_and_descendants_avg_ms",
        "self_and_descendants_min_ms",
        "self_and_descendants_max_ms",
        "self_and_ancestors_avg_ms",
        "self_and_ancestors_min_ms",
        "self_and_ancestors_max_ms",
        "delete_time_ms"
      ].join(";")
    end

    def create_tree(nodes_number, generations)
      if nodes_number < generations + 1
        raise ArgumentError, "Nodes number (#{nodes_number}) must be at least #{generations + 1} to create #{generations} generations"
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


    # Crea un albero dato numero nodo e generazioni
    # Calcola il benchmark per il nodo più profondo
    # Calcola il benchmark per tutti i nodi
    # Elimina l'albero
    # Torna un oggetto BenchmarkResultsAggregate
    def test_tree(nodes_number, generations)
      puts "Create tree with #{nodes_number} nodes and #{generations} generations..."
      @root = create_tree(nodes_number, generations)
      puts "✓ Tree created successfully:"
      print_tree(@root)


      puts "Deepest node:"
      deepest_node = @root.descendants.max_by(&:depth)
      print_node(deepest_node)
      puts "Benchmark for deepest node:"
      deepest_node_benchmark_result = BenchmarkResult.new(deepest_node)
      puts deepest_node_benchmark_result
      puts "-"*80

      puts "Calculate benchmark for all nodes..."
      @closure_table_size = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM node_hierarchies").first["count"].to_i
      puts "Closure table size: #{@closure_table_size}"
      benchmark_results_aggregate = BenchmarkResultsAggregate.new(nodes_number, generations, @closure_table_size)
      @root.self_and_descendants.each_with_index do |node, index|
        benchmark_results_aggregate << BenchmarkResult.new(node)
      end
      puts "✓ Benchmark calculated successfully"

      benchmark_results_aggregate.print_stats("root", :root_time)
      benchmark_results_aggregate.print_stats("self_and_descendants", :self_and_descendants_time)
      benchmark_results_aggregate.print_stats("self_and_ancestors", :self_and_ancestors_time)

      puts "Delete tree..."
      destroy_time = Benchmark.measure { @root.destroy }.real*1000
      puts "✓ Tree deleted in #{(destroy_time).round(3)} ms"
      benchmark_results_aggregate.delete_time = destroy_time

      benchmark_results_aggregate
    end


    puts "\n" + "="*80
    puts "TEST CLOSURE_TREE"
    puts "="*80 + "\n"

    @benchmark_results_aggregate_global = []
    for nodes_number in [ 10, 20 ]
      for generations in [ 2, 5, 10 ]
        if generations > nodes_number-1
          next
        end
        benchmark_results_aggregate = test_tree(nodes_number, generations)
        @benchmark_results_aggregate_global << benchmark_results_aggregate
      end
    end

    puts "Export results to CSV..."
    File.open("closure_tree_test_results.csv", "w") do |file|
      file.write(csv_header + "\n")
      @benchmark_results_aggregate_global.each do |result|
        file.write(result.to_csv + "\n")
      end
    end
    puts "✓ Results exported to closure_tree_test_results.csv"

    puts "Delete all nodes..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE node_hierarchies, nodes RESTART IDENTITY CASCADE")
    puts "✓ All nodes deleted"
  end

  task test_creation: :environment do
    csv_header = [
      "nodes_number",
      "closure_table_size",
      "creation_time_ms"
    ].join(";")
    puts "Delete all nodes..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE node_hierarchies, nodes RESTART IDENTITY CASCADE")
    puts "✓ All nodes deleted"
    nodes_number = (ENV["NODES_NUMBER"] || 100).to_i
    @benchmark_creation_results_aggregate = []
    index=1
    puts "#{index}/#{nodes_number}"
    root = Node.create!(name: "n#{index}")
    index += 1
    flat_tree=[]
    flat_tree << root
    (nodes_number-1).times do |i|
      if index%100==0 || index==nodes_number
        puts "#{index}/#{nodes_number}"
      end
      random_node = flat_tree.sample
      @closure_table_size = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM node_hierarchies").first["count"].to_i
      creation_time = Benchmark.measure {
        @new_node = Node.create!(name: "n#{index}")
        random_node.children << @new_node
      }.real*1000
      flat_tree << @new_node
      benchmark_creation_result = BenchmarkCreationResult.new(flat_tree.size, @closure_table_size, creation_time)
      @benchmark_creation_results_aggregate << benchmark_creation_result
      index += 1
    end
    root.reload
    # print_tree(root)
    puts "Stats:"
    @average_creation_time = @benchmark_creation_results_aggregate.map(&:creation_time).sum / @benchmark_creation_results_aggregate.size
    @min_creation_time = @benchmark_creation_results_aggregate.map(&:creation_time).min
    @max_creation_time = @benchmark_creation_results_aggregate.map(&:creation_time).max
    puts "Average creation time: #{@average_creation_time.round(3)} ms"
    puts "Min creation time: #{@min_creation_time.round(3)} ms"
    puts "Max creation time: #{@max_creation_time.round(3)} ms"

    plot_creation_results(@benchmark_creation_results_aggregate)

    puts "Export results to CSV..."
    File.open("closure_tree_test_results.csv", "w") do |file|
      file.write(csv_header + "\n")
      @benchmark_creation_results_aggregate.each do |result|
        file.write(result.to_csv + "\n")
      end
    end
    puts "✓ Results exported to closure_tree_test_results.csv"
  end
end
