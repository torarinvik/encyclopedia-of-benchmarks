from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_VERTICES = 64
alias MAX_EDGES = 128
alias MAX_INPUT_LENGTH = 259

struct BridgeState:
    var dsu_2ecc: InlineArray[Int64, MAX_VERTICES]
    var dsu_cc: InlineArray[Int64, MAX_VERTICES]
    var dsu_cc_size: InlineArray[Int64, MAX_VERTICES]
    var parent: InlineArray[Int64, MAX_VERTICES]
    var last_visit: InlineArray[Int64, MAX_VERTICES]
    var iteration: Int64
    var bridges: Int64

    fn __init__(out self):
        self.dsu_2ecc = InlineArray[Int64, MAX_VERTICES](0)
        self.dsu_cc = InlineArray[Int64, MAX_VERTICES](0)
        self.dsu_cc_size = InlineArray[Int64, MAX_VERTICES](0)
        self.parent = InlineArray[Int64, MAX_VERTICES](-1)
        self.last_visit = InlineArray[Int64, MAX_VERTICES](0)
        self.iteration = 0
        self.bridges = 0

    fn find_2ecc(mut self, vertex: Int64) -> Int64:
        if vertex == -1: return -1
        var index = Int(vertex)
        if self.dsu_2ecc[index] == vertex: return vertex
        var next = self.dsu_2ecc[index]
        self.dsu_2ecc[index] = self.find_2ecc(next)
        return self.dsu_2ecc[index]

    fn find_cc(mut self, vertex_input: Int64) -> Int64:
        var vertex = self.find_2ecc(vertex_input)
        var index = Int(vertex)
        if self.dsu_cc[index] == vertex: return vertex
        var next = self.dsu_cc[index]
        self.dsu_cc[index] = self.find_cc(next)
        return self.dsu_cc[index]

    fn make_root(mut self, vertex_input: Int64):
        var root = self.find_2ecc(vertex_input)
        var vertex = root
        var child: Int64 = -1
        while vertex != -1:
            var index = Int(vertex)
            var parent = self.parent[index]
            var next = self.find_2ecc(parent)
            self.parent[index] = child
            self.dsu_cc[index] = root
            child = vertex
            vertex = next
        self.dsu_cc_size[Int(root)] = self.dsu_cc_size[Int(child)]

    fn merge_path(mut self, left_input: Int64, right_input: Int64):
        self.iteration += 1
        var path_left = InlineArray[Int64, MAX_VERTICES](0)
        var path_right = InlineArray[Int64, MAX_VERTICES](0)
        var left_length = 0
        var right_length = 0
        var left = left_input
        var right = right_input
        var lca: Int64 = -1
        while lca == -1:
            if left != -1:
                left = self.find_2ecc(left)
                var index = Int(left)
                path_left[left_length] = left
                left_length += 1
                if self.last_visit[index] == self.iteration:
                    lca = left
                    break
                self.last_visit[index] = self.iteration
                left = self.parent[index]
            if right != -1:
                right = self.find_2ecc(right)
                var index = Int(right)
                path_right[right_length] = right
                right_length += 1
                if self.last_visit[index] == self.iteration:
                    lca = right
                    break
                self.last_visit[index] = self.iteration
                right = self.parent[index]
        for index in range(left_length):
            var vertex = path_left[index]
            self.dsu_2ecc[Int(vertex)] = lca
            if vertex == lca: break
            self.bridges -= 1
        for index in range(right_length):
            var vertex = path_right[index]
            self.dsu_2ecc[Int(vertex)] = lca
            if vertex == lca: break
            self.bridges -= 1

    fn add_edge(mut self, left_input: Int64, right_input: Int64):
        var left = self.find_2ecc(left_input)
        var right = self.find_2ecc(right_input)
        if left == right: return
        var left_cc = self.find_cc(left)
        var right_cc = self.find_cc(right)
        if left_cc != right_cc:
            self.bridges += 1
            if self.dsu_cc_size[Int(left_cc)] > self.dsu_cc_size[Int(right_cc)]:
                var temporary = left
                left = right
                right = temporary
                temporary = left_cc
                left_cc = right_cc
                right_cc = temporary
            self.make_root(left)
            self.parent[Int(left)] = right
            self.dsu_cc[Int(left)] = right
            self.dsu_cc_size[Int(right_cc)] += self.dsu_cc_size[Int(left)]
        else:
            self.merge_path(left, right)

fn store_i64_le(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int):
    var bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & 0xff)

@export("online_bridge_finding")
fn online_bridge_finding(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
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
    var output_bytes = edge_count * 8
    if output_bytes > 0 and (output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes)):
        return -2

    var state = BridgeState()
    for vertex in range(vertex_count):
        state.dsu_2ecc[vertex] = Int64(vertex)
        state.dsu_cc[vertex] = Int64(vertex)
        state.dsu_cc_size[vertex] = 1
    for edge in range(edge_count):
        state.add_edge(values[2 + 2 * edge], values[3 + 2 * edge])
        store_i64_le(state.bridges, output, edge * 8)
    return Int64(output_bytes)
