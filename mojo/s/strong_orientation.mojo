from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_VERTICES = 64
alias MAX_EDGES = 128
alias MAX_ARCS = 2 * MAX_EDGES
alias MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES + 1

struct Graph:
    var head: InlineArray[Int64, MAX_VERTICES]
    var tail: InlineArray[Int64, MAX_VERTICES]
    var to: InlineArray[Int64, MAX_ARCS]
    var next: InlineArray[Int64, MAX_ARCS]
    var arc_edge: InlineArray[Int64, MAX_ARCS]
    var edge_u: InlineArray[Int64, MAX_EDGES]
    var edge_used: InlineArray[Int64, MAX_EDGES]
    var direction: InlineArray[Int64, MAX_EDGES]
    var discovery: InlineArray[Int64, MAX_VERTICES]
    var low: InlineArray[Int64, MAX_VERTICES]
    var timer: Int64
    var bridges: Int64

    fn __init__(out self):
        self.head = InlineArray[Int64, MAX_VERTICES](-1)
        self.tail = InlineArray[Int64, MAX_VERTICES](-1)
        self.to = InlineArray[Int64, MAX_ARCS](0)
        self.next = InlineArray[Int64, MAX_ARCS](-1)
        self.arc_edge = InlineArray[Int64, MAX_ARCS](0)
        self.edge_u = InlineArray[Int64, MAX_EDGES](0)
        self.edge_used = InlineArray[Int64, MAX_EDGES](0)
        self.direction = InlineArray[Int64, MAX_EDGES](0)
        self.discovery = InlineArray[Int64, MAX_VERTICES](-1)
        self.low = InlineArray[Int64, MAX_VERTICES](0)
        self.timer = 0
        self.bridges = 0

    fn append_arc(mut self, from: Int, target: Int, edge: Int, mut arc_count: Int):
        var arc = arc_count
        arc_count += 1
        self.to[arc] = Int64(target)
        self.arc_edge[arc] = Int64(edge)
        self.next[arc] = -1
        if self.head[from] == -1:
            self.head[from] = Int64(arc)
        else:
            self.next[Int(self.tail[from])] = Int64(arc)
        self.tail[from] = Int64(arc)

    fn visit(mut self, vertex: Int):
        self.discovery[vertex] = self.timer
        self.low[vertex] = self.timer
        self.timer += 1
        var arc = self.head[vertex]
        while arc != -1:
            var arc_index = Int(arc)
            var next_arc = self.next[arc_index]
            var edge = Int(self.arc_edge[arc_index])
            if self.edge_used[edge] == 0:
                self.edge_used[edge] = 1
                self.direction[edge] = 1 if vertex == Int(self.edge_u[edge]) else -1
                var neighbor = Int(self.to[arc_index])
                if self.discovery[neighbor] == -1:
                    self.visit(neighbor)
                    if self.low[neighbor] < self.low[vertex]: self.low[vertex] = self.low[neighbor]
                    if self.low[neighbor] > self.discovery[vertex]: self.bridges += 1
                elif self.discovery[neighbor] < self.low[vertex]:
                    self.low[vertex] = self.discovery[neighbor]
            arc = next_arc

fn store_i64_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & 0xff)

@export("strong_orientation")
fn strong_orientation(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                      output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    var raw_vertices = values[0]
    var raw_edges = values[1]
    if raw_vertices < 1 or raw_vertices > MAX_VERTICES or raw_edges < 0 or raw_edges > MAX_EDGES:
        return -1
    var vertex_count = Int(raw_vertices)
    var edge_count = Int(raw_edges)
    if length != c_size_t(2 + 2 * edge_count): return -1
    for edge in range(edge_count):
        var left = values[2 + 2 * edge]
        var right = values[3 + 2 * edge]
        if left < 0 or right < 0 or left >= raw_vertices or right >= raw_vertices: return -1
    var output_bytes = 8 * (edge_count + 1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2

    var graph = Graph()
    var arc_count = 0
    for edge in range(edge_count):
        var left = Int(values[2 + 2 * edge])
        var right = Int(values[3 + 2 * edge])
        graph.edge_u[edge] = Int64(left)
        graph.append_arc(left, right, edge, arc_count)
        graph.append_arc(right, left, edge, arc_count)
    var components = 0
    for vertex in range(vertex_count):
        if graph.discovery[vertex] == -1:
            components += 1
            graph.visit(vertex)
    store_i64_le(Int64(components + Int(graph.bridges)), output, 0)
    for edge in range(edge_count):
        store_i64_le(graph.direction[edge], output, 8 * (edge + 1))
    return Int64(output_bytes)
