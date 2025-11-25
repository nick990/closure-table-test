class BenchmarkResultsAggregate < Array
  attr_reader :nodes_number, :generations, :closure_table_size, :delete_time

  def initialize(nodes_number, generations, closure_table_size, *args)
    super(*args)
    @nodes_number = nodes_number
    @generations = generations
    @closure_table_size = closure_table_size
    @delete_time = nil
  end

  def delete_time=(time)
    @delete_time = time
  end

  def min_time(metric)
    min_by { |r| r.send(metric) }
  end

  def max_time(metric)
    max_by { |r| r.send(metric) }
  end

  def average_time(metric)
    return 0.0 if empty?
    map { |r| r.send(metric) }.sum / size
  end

  def print_stats(title, metric)
    puts "\n" + "="*80
    puts "BENCHMARK: #{title}"
    puts "="*80
    res_min = min_time(metric)
    puts "Min time: #{res_min.send(metric).round(3)} ms\n\t└─ Node: #{res_min.node.name} (Depth: #{res_min.node.depth})"
    res_max = max_time(metric)
    puts "Max time: #{res_max.send(metric).round(3)} ms\n\t└─ Node: #{res_max.node.name} (Depth: #{res_max.node.depth})"
    puts "Average time:  #{average_time(metric).round(3)} ms"
    puts "="*80
  end

  def to_csv
    [
      nodes_number,
      generations,
      closure_table_size,
      average_time(:root_time).round(3).to_s.gsub(".", ","),
      min_time(:root_time).send(:root_time).round(3).to_s.gsub(".", ","),
      max_time(:root_time).send(:root_time).round(3).to_s.gsub(".", ","),
      average_time(:self_and_descendants_time).round(3).to_s.gsub(".", ","),
      min_time(:self_and_descendants_time).send(:self_and_descendants_time).round(3).to_s.gsub(".", ","),
      max_time(:self_and_descendants_time).send(:self_and_descendants_time).round(3).to_s.gsub(".", ","),
      average_time(:self_and_ancestors_time).round(3).to_s.gsub(".", ","),
      min_time(:self_and_ancestors_time).send(:self_and_ancestors_time).round(3).to_s.gsub(".", ","),
      max_time(:self_and_ancestors_time).send(:self_and_ancestors_time).round(3).to_s.gsub(".", ","),
      delete_time ? delete_time.round(3).to_s.gsub(".", ",") : ""
    ].join(";")
  end
end
