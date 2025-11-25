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
    s="Node: #{node.name} (ID: #{node.id}, Depth: #{node.depth})\n"
    s+="\troot: #{root_time.round(3)} ms\n"
    s+="\tself_and_descendants: #{self_and_descendants_time.round(3)} ms\n"
    s+="\tself_and_ancestors: #{self_and_ancestors_time.round(3)} ms"
    s
  end
end
