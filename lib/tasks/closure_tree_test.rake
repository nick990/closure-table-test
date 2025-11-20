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

    puts "\n" + "="*80
    puts "TEST CLOSURE_TREE"
    puts "="*80 + "\n"

    puts "Cancello tutti i nodi..."
    Node.destroy_all
    ActiveRecord::Base.connection.execute("ALTER SEQUENCE nodes_id_seq RESTART WITH 1")
    puts "✓ Tutti i nodi cancellati"


    puts "Creo l'albero..."
    @n1 = Node.create!(name: "n1")
    @n2 = @n1.children.create!(name: "n2")
    @n3 = @n2.children.create!(name: "n3")
    @n4 = @n1.children.create!(name: "n4")
    @n5 = @n4.children.create!(name: "n5")
    @n6 = @n4.children.create!(name: "n6")
    @n7 = @n6.children.create!(name: "n7")
    @n8 = @n5.children.create!(name: "n8")
    @n9 = @n6.children.create!(name: "n9")
    @n10 = @n5.children.create!(name: "n10")
    puts "✓ Albero creato con successo"
    print_tree(@n1)
  end
end
