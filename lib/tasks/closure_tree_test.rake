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
      root = Node.create!(name: "n1")
      index=2
      last_node=root
      (generations).times do |i|
        new_node = Node.create!(name: "n#{index}")
        last_node.children << new_node
        last_node = new_node
        index += 1
      end
      nodes_number-=(generations+1)
      nodes_number.times do |i|
        new_node = Node.create!(name: "n#{index}")
        all_nodes = root.self_and_descendants.to_a
        random_node = all_nodes.sample
        random_node.children << new_node
        index += 1
      end
      root
    end

    puts "\n" + "="*80
    puts "TEST CLOSURE_TREE"
    puts "="*80 + "\n"

    puts "Cancello tutti i nodi..."
    Node.destroy_all
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE nodes_id_seq RESTART WITH 1")
    puts "✓ Tutti i nodi cancellati"


    puts "Creo l'albero..."
    @root = create_tree(500, 30)
    print_tree(@root)
    puts "✓ Albero creato con successo"
  end
end
