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

    puts "\n" + "="*80
    puts "TEST CLOSURE_TREE"
    puts "="*80 + "\n"

    puts "Cancello tutti i nodi..."
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE node_hierarchies, nodes RESTART IDENTITY CASCADE")
    puts "✓ Tutti i nodi cancellati"


    nodes_number=30
    generations=9
    puts "Creo l'albero con #{nodes_number} nodi e #{generations} generazioni..."
    @root = create_tree(nodes_number, generations)
    puts "✓ Albero creato con successo:"
    print_tree(@root)
  end
end
