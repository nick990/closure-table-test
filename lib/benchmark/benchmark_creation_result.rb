class BenchmarkCreationResult
  attr_reader :nodes_number, :closure_table_size, :depth, :creation_time

  def initialize(nodes_number, closure_table_size, depth, creation_time)
    @nodes_number = nodes_number
    @closure_table_size = closure_table_size
    @depth = depth
    @creation_time = creation_time
  end

  def to_s
    s="Depth: #{depth}\n"
    s+="\tNodes number: #{nodes_number}\n"
    s+="\tClosure table size: #{closure_table_size}\n"
    s+="\tCreation time: #{creation_time.round(3)} ms"
    s
  end

  def to_csv
    [
      nodes_number,
      closure_table_size,
      depth,
      creation_time.round(3).to_s.gsub(".", ",")
    ].join(";")
  end
end
