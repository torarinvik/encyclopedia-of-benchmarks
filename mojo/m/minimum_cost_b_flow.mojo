from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 8
comptime MAX_EDGES = 10
comptime MAX_ARCS = 2 * MAX_EDGES + 2 * MAX_VERTICES
comptime MAX_NODES = MAX_VERTICES + 2
comptime MAX_INPUT_LENGTH = 2 + MAX_VERTICES + 5 * MAX_EDGES + 1
comptime MAX_OUTPUT_WORDS = 2 + MAX_VERTICES + MAX_EDGES

struct ResidualGraph:
    var from: InlineArray[Int, MAX_ARCS]
    var to: InlineArray[Int, MAX_ARCS]
    var reverse: InlineArray[Int, MAX_ARCS]
    var capacity: InlineArray[Int64, MAX_ARCS]
    var cost: InlineArray[Int64, MAX_ARCS]
    var arc_count: Int
    var original_arc_count: Int

    fn __init__(out self):
        self.from = InlineArray[Int, MAX_ARCS](fill=0)
        self.to = InlineArray[Int, MAX_ARCS](fill=0)
        self.reverse = InlineArray[Int, MAX_ARCS](fill=0)
        self.capacity = InlineArray[Int64, MAX_ARCS](fill=0)
        self.cost = InlineArray[Int64, MAX_ARCS](fill=0)
        self.arc_count = 0
        self.original_arc_count = 0

    fn add_edge(mut self, source: Int, target: Int, cap: Int64, price: Int64):
        let forward = self.arc_count
        let backward = forward + 1
        self.arc_count += 2
        self.from[forward] = source
        self.to[forward] = target
        self.reverse[forward] = backward
        self.capacity[forward] = cap
        self.cost[forward] = price
        self.from[backward] = target
        self.to[backward] = source
        self.reverse[backward] = forward
        self.capacity[backward] = 0
        self.cost[backward] = -price

    fn feasible_flow(mut self, vertex_count: Int, required_flow: Int64) -> Bool:
        let super_source = vertex_count
        let super_sink = vertex_count + 1
        var sent: Int64 = 0
        while sent < required_flow:
            var parent = InlineArray[Int, MAX_NODES](fill=-1)
            var seen = InlineArray[Int, MAX_NODES](fill=0)
            var queue = InlineArray[Int, MAX_NODES](fill=0)
            var head = 0
            var queue_length = 1
            seen[super_source] = 1
            queue[0] = super_source
            while head < queue_length:
                let vertex = queue[head]
                head += 1
                for edge in range(self.arc_count):
                    let neighbor = self.to[edge]
                    if self.from[edge] == vertex and self.capacity[edge] > 0 and seen[neighbor] == 0:
                        seen[neighbor] = 1
                        parent[neighbor] = edge
                        queue[queue_length] = neighbor
                        queue_length += 1
            if seen[super_sink] == 0:
                return False
            var amount = required_flow - sent
            var vertex = super_sink
            while vertex != super_source:
                let edge = parent[vertex]
                if amount > self.capacity[edge]:
                    amount = self.capacity[edge]
                vertex = self.from[edge]
            vertex = super_sink
            while vertex != super_source:
                let edge = parent[vertex]
                self.capacity[edge] -= amount
                self.capacity[self.reverse[edge]] += amount
                vertex = self.from[edge]
            sent += amount
        return True

    fn cancel_negative_cycles(mut self, vertex_count: Int) -> Bool:
        if vertex_count == 0:
            return True
        while True:
            var distance = InlineArray[Int64, MAX_VERTICES](fill=0)
            var parent = InlineArray[Int, MAX_VERTICES](fill=-1)
            var changed_vertex = -1
            for _ in range(vertex_count):
                changed_vertex = -1
                for edge in range(self.original_arc_count):
                    let source = self.from[edge]
                    let target = self.to[edge]
                    if self.capacity[edge] > 0 and distance[target] > distance[source] + self.cost[edge]:
                        distance[target] = distance[source] + self.cost[edge]
                        parent[target] = edge
                        changed_vertex = target
                if changed_vertex == -1:
                    break
            if changed_vertex == -1:
                return True
            var on_cycle = changed_vertex
            for _ in range(vertex_count):
                let edge = parent[on_cycle]
                on_cycle = self.from[edge]
            var amount: Int64 = 1 << 60
            var vertex = on_cycle
            while True:
                let edge = parent[vertex]
                if amount > self.capacity[edge]:
                    amount = self.capacity[edge]
                vertex = self.from[edge]
                if vertex == on_cycle:
                    break
            vertex = on_cycle
            while True:
                let edge = parent[vertex]
                self.capacity[edge] -= amount
                self.capacity[self.reverse[edge]] += amount
                vertex = self.from[edge]
                if vertex == on_cycle:
                    break


fn solve(n: Int, m: Int, input: UnsafePointer[Int64, ImmutAnyOrigin],
         mut words: InlineArray[Int64, MAX_OUTPUT_WORDS]) -> Bool:
    let edge_offset = 2 + n
    var required = InlineArray[Int64, MAX_VERTICES](fill=0)
    for vertex in range(n):
        required[vertex] = input[2 + vertex]
    for edge in range(m):
        let offset = edge_offset + 5 * edge
        let source = Int(input[offset])
        let target = Int(input[offset + 1])
        let lower = input[offset + 2]
        required[source] -= lower
        required[target] += lower
    var required_sum: Int64 = 0
    var required_flow: Int64 = 0
    for vertex in range(n):
        required_sum += required[vertex]
        if required[vertex] > 0:
            required_flow += required[vertex]
    if required_sum != 0:
        return False

    var graph = ResidualGraph()
    for edge in range(m):
        let offset = edge_offset + 5 * edge
        graph.add_edge(Int(input[offset]), Int(input[offset + 1]),
            input[offset + 3] - input[offset + 2], input[offset + 4])
    graph.original_arc_count = graph.arc_count
    for vertex in range(n):
        if required[vertex] > 0:
            graph.add_edge(n, vertex, required[vertex], 0)
        elif required[vertex] < 0:
            graph.add_edge(vertex, n + 1, -required[vertex], 0)
    if not graph.feasible_flow(n, required_flow) or not graph.cancel_negative_cycles(n):
        return False

    var potential = InlineArray[Int64, MAX_VERTICES](fill=0)
    for _ in range(max(0, n - 1)):
        var changed = False
        for edge in range(graph.original_arc_count):
            let source = graph.from[edge]
            let target = graph.to[edge]
            if graph.capacity[edge] > 0 and potential[target] > potential[source] + graph.cost[edge]:
                potential[target] = potential[source] + graph.cost[edge]
                changed = True
        if not changed:
            break
    words[0] = 1
    words[1] = 0
    for vertex in range(n):
        words[2 + vertex] = potential[vertex]
    for edge in range(m):
        let offset = edge_offset + 5 * edge
        let flow = input[offset + 3] - graph.capacity[2 * edge]
        words[2 + n + edge] = flow
        words[1] += flow * input[offset + 4]
    return True


fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))


@export("minimum_cost_b_flow")
fn minimum_cost_b_flow(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT_LENGTH:
        return -1
    let raw_n = input[0]
    let raw_m = input[1]
    if raw_n < 0 or raw_n > MAX_VERTICES or raw_m < 0 or raw_m > MAX_EDGES:
        return -1
    let n = Int(raw_n)
    let m = Int(raw_m)
    if length != c_size_t(2 + n + 5 * m):
        return -1
    for vertex in range(n):
        if input[2 + vertex] < -5 or input[2 + vertex] > 5:
            return -1
    let edge_offset = 2 + n
    for edge in range(m):
        let offset = edge_offset + 5 * edge
        let source = input[offset]
        let target = input[offset + 1]
        let lower = input[offset + 2]
        let upper = input[offset + 3]
        let price = input[offset + 4]
        if source < 0 or source >= raw_n or target < 0 or target >= raw_n or lower < -3 or upper > 3 or lower > upper or upper - lower > 2 or price < -4 or price > 4:
            return -1
    let output_bytes = 8 * (2 + n + m)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(output_bytes):
        return -2
    var words = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    if not solve(n, m, input, words):
        words = InlineArray[Int64, MAX_OUTPUT_WORDS](fill=0)
    for word in range(2 + n + m):
        store_i64_le(output, 8 * word, words[word])
    return Int64(output_bytes)
