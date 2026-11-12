"""Classical DFS low-link decomposition into vertex-biconnected blocks."""
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 6
alias MAX_M = 10
alias MAX_ADJ = 20
alias MAX_BLOCKS = MAX_N + MAX_M
alias MAX_OUTPUT_VALUES = 113
alias MAX_OUTPUT_BYTES = 904
alias MAX_INPUT_LENGTH = 22

struct Graph:
    var n: Int
    var m: Int
    var edge_left: InlineArray[Int64, MAX_M]
    var edge_right: InlineArray[Int64, MAX_M]
    var degree: InlineArray[Int64, MAX_N]
    var adjacent_vertex: InlineArray[Int64, MAX_N * MAX_ADJ]
    var adjacent_edge: InlineArray[Int64, MAX_N * MAX_ADJ]
    var discovery: InlineArray[Int64, MAX_N]
    var low: InlineArray[Int64, MAX_N]
    var edge_stack: InlineArray[Int64, MAX_M]
    var stack_size: Int
    var clock: Int
    var block_vertices: InlineArray[Int64, MAX_BLOCKS * MAX_N]
    var block_size: InlineArray[Int64, MAX_BLOCKS]
    var block_count: Int

    fn __init__(out self):
        self.n = 0
        self.m = 0
        self.edge_left = InlineArray[Int64, MAX_M](0)
        self.edge_right = InlineArray[Int64, MAX_M](0)
        self.degree = InlineArray[Int64, MAX_N](0)
        self.adjacent_vertex = InlineArray[Int64, MAX_N * MAX_ADJ](0)
        self.adjacent_edge = InlineArray[Int64, MAX_N * MAX_ADJ](0)
        self.discovery = InlineArray[Int64, MAX_N](-1)
        self.low = InlineArray[Int64, MAX_N](0)
        self.edge_stack = InlineArray[Int64, MAX_M](0)
        self.stack_size = 0
        self.clock = 0
        self.block_vertices = InlineArray[Int64, MAX_BLOCKS * MAX_N](0)
        self.block_size = InlineArray[Int64, MAX_BLOCKS](0)
        self.block_count = 0

    fn append_block(mut self, stop_edge: Int):
        var member = InlineArray[Int64, MAX_N](0)
        while self.stack_size > 0:
            self.stack_size -= 1
            let edge = Int(self.edge_stack[self.stack_size])
            member[Int(self.edge_left[edge])] = 1
            member[Int(self.edge_right[edge])] = 1
            if edge == stop_edge: break
        let block = self.block_count
        self.block_count += 1
        for vertex in range(self.n):
            if member[vertex] != 0:
                let offset = block * MAX_N + Int(self.block_size[block])
                self.block_vertices[offset] = Int64(vertex)
                self.block_size[block] += 1

    fn visit(mut self, vertex: Int, parent_edge: Int):
        self.discovery[vertex] = Int64(self.clock)
        self.low[vertex] = Int64(self.clock)
        self.clock += 1
        for slot in range(Int(self.degree[vertex])):
            let offset = vertex * MAX_ADJ + slot
            let neighbor = Int(self.adjacent_vertex[offset])
            let edge = Int(self.adjacent_edge[offset])
            if edge == parent_edge: continue
            if self.discovery[neighbor] < 0:
                self.edge_stack[self.stack_size] = Int64(edge)
                self.stack_size += 1
                self.visit(neighbor, edge)
                self.low[vertex] = min(self.low[vertex], self.low[neighbor])
                if self.low[neighbor] >= self.discovery[vertex]: self.append_block(edge)
            elif self.discovery[neighbor] < self.discovery[vertex]:
                self.edge_stack[self.stack_size] = Int64(edge)
                self.stack_size += 1
                self.low[vertex] = min(self.low[vertex], self.discovery[neighbor])

    fn block_less(self, left: Int, right: Int) -> Bool:
        let left_size = Int(self.block_size[left])
        let right_size = Int(self.block_size[right])
        let common = min(left_size, right_size)
        for i in range(common):
            let a = self.block_vertices[left * MAX_N + i]
            let b = self.block_vertices[right * MAX_N + i]
            if a != b: return a < b
        return left_size < right_size

fn store_u64_le(value: UInt64, mut output: InlineArray[UInt8, MAX_OUTPUT_BYTES], offset: Int):
    for byte in range(8):
        output[offset + byte] = UInt8((value >> (byte * 8)) & 0xff)

@export("biconnected_components")
fn biconnected_components(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH: return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_N or m_value < 0 or m_value > MAX_M: return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m): return -1

    var graph = Graph()
    graph.n = n
    graph.m = m
    for edge in range(m):
        let left_value = input[2 + 2 * edge]
        let right_value = input[3 + 2 * edge]
        if left_value < 0 or left_value >= n_value or right_value < 0 or
            right_value >= n_value or left_value == right_value: return -1
        let left = Int(left_value)
        let right = Int(right_value)
        graph.edge_left[edge] = left_value
        graph.edge_right[edge] = right_value
        let left_slot = Int(graph.degree[left])
        let right_slot = Int(graph.degree[right])
        graph.degree[left] += 1
        graph.degree[right] += 1
        graph.adjacent_vertex[left * MAX_ADJ + left_slot] = right_value
        graph.adjacent_edge[left * MAX_ADJ + left_slot] = Int64(edge)
        graph.adjacent_vertex[right * MAX_ADJ + right_slot] = left_value
        graph.adjacent_edge[right * MAX_ADJ + right_slot] = Int64(edge)
    for root in range(n):
        if graph.discovery[root] >= 0: continue
        graph.visit(root, MAX_M)
        if graph.degree[root] == 0:
            let block = graph.block_count
            graph.block_count += 1
            graph.block_vertices[block * MAX_N] = Int64(root)
            graph.block_size[block] = 1

    var order = InlineArray[Int64, MAX_BLOCKS](0)
    for i in range(MAX_BLOCKS): order[i] = Int64(i)
    for i in range(graph.block_count):
        var position = i
        while position > 0 and graph.block_less(Int(order[position]), Int(order[position - 1])):
            let temporary = order[position]
            order[position] = order[position - 1]
            order[position - 1] = temporary
            position -= 1
    var staged = InlineArray[UInt8, MAX_OUTPUT_BYTES](0)
    var packed_count = 0
    store_u64_le(UInt64(graph.block_count), staged, packed_count * 8)
    packed_count += 1
    for i in range(graph.block_count):
        let block = Int(order[i])
        store_u64_le(UInt64(graph.block_size[block]), staged, packed_count * 8)
        packed_count += 1
        for j in range(Int(graph.block_size[block])):
            store_u64_le(UInt64(graph.block_vertices[block * MAX_N + j]), staged, packed_count * 8)
            packed_count += 1
    let bytes = 8 * packed_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(bytes): output[byte] = staged[byte]
    return Int64(bytes)
