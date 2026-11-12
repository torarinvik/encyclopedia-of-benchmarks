from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_M = 16
comptime MAX_INPUT = 69
comptime INF = Int64(1) << 60

struct ResidualNetwork:
    var from_vertex: InlineArray[Int, 32]
    var to_vertex: InlineArray[Int, 32]
    var reverse: InlineArray[Int, 32]
    var capacity: InlineArray[Int64, 32]
    var cost: InlineArray[Int64, 32]

    fn __init__(out self):
        self.from_vertex = InlineArray[Int, 32](fill=0)
        self.to_vertex = InlineArray[Int, 32](fill=0)
        self.reverse = InlineArray[Int, 32](fill=0)
        self.capacity = InlineArray[Int64, 32](fill=0)
        self.cost = InlineArray[Int64, 32](fill=0)

    fn send_tight_level_flow(mut self, u: Int, sink: Int, limit: Int64, arc_count: Int,
            dist: InlineArray[Int64, 8], level: InlineArray[Int, 8],
            mut current: InlineArray[Int, 8]) -> Int64:
        if u == sink:
            return limit
        while current[u] < arc_count:
            let edge = current[u]
            if self.from_vertex[edge] != u or self.capacity[edge] <= 0:
                current[u] += 1
                continue
            let v = self.to_vertex[edge]
            if dist[v] == INF or dist[v] != dist[u] + self.cost[edge] or level[v] != level[u] + 1:
                current[u] += 1
                continue
            let amount = min(limit, self.capacity[edge])
            let sent = self.send_tight_level_flow(v, sink, amount, arc_count, dist, level, mut current)
            if sent > 0:
                let reverse_edge = self.reverse[edge]
                self.capacity[edge] -= sent
                self.capacity[reverse_edge] += sent
                if self.capacity[edge] == 0:
                    current[u] += 1
                return sent
            current[u] += 1
        return 0

@export("min_cost_max_flow_blocking_paths")
fn min_cost_max_flow_blocking_paths(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(5) or length > c_size_t(MAX_INPUT):
        return -1
    let n_value = input[0]
    let m_value = input[1]
    let source_value = input[2]
    let sink_value = input[3]
    let flow_limit = input[4]
    if n_value < 2 or n_value > MAX_N or m_value < 0 or m_value > MAX_M:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if Int(length) != 5 + 4 * m:
        return -1
    if source_value < 0 or source_value >= n_value or sink_value < 0 or sink_value >= n_value or
            source_value == sink_value or flow_limit < 0 or flow_limit > 16:
        return -1
    let source = Int(source_value)
    let sink = Int(sink_value)
    var network = ResidualNetwork()
    for i in range(m):
        let u_value = input[5 + 4 * i]
        let v_value = input[6 + 4 * i]
        let cap = input[7 + 4 * i]
        let edge_cost = input[8 + 4 * i]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or
                cap < 0 or cap > 5 or edge_cost < 0 or edge_cost > 20:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        let edge = 2 * i
        network.from_vertex[edge] = u
        network.to_vertex[edge] = v
        network.reverse[edge] = edge + 1
        network.capacity[edge] = cap
        network.cost[edge] = edge_cost
        network.from_vertex[edge + 1] = v
        network.to_vertex[edge + 1] = u
        network.reverse[edge + 1] = edge
        network.capacity[edge + 1] = 0
        network.cost[edge + 1] = -edge_cost
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(16):
        return -2
    var total_flow: Int64 = 0
    var total_cost: Int64 = 0
    while total_flow < flow_limit:
        var dist = InlineArray[Int64, MAX_N](fill=INF)
        var queue = InlineArray[Int, MAX_N](fill=0)
        var in_queue = InlineArray[Bool, MAX_N](fill=False)
        dist[source] = 0
        var head = 0
        var tail = 0
        var queued = 0
        queue[tail] = source
        tail = (tail + 1) % n
        queued += 1
        in_queue[source] = True
        while queued > 0:
            let u = queue[head]
            head = (head + 1) % n
            queued -= 1
            in_queue[u] = False
            for edge in range(2 * m):
                if network.from_vertex[edge] != u or network.capacity[edge] <= 0:
                    continue
                let v = network.to_vertex[edge]
                let candidate = dist[u] + network.cost[edge]
                if candidate < dist[v]:
                    dist[v] = candidate
                    if not in_queue[v]:
                        queue[tail] = v
                        tail = (tail + 1) % n
                        queued += 1
                        in_queue[v] = True
        if dist[sink] == INF:
            break
        while total_flow < flow_limit:
            var level = InlineArray[Int, MAX_N](fill=-1)
            var breadth = InlineArray[Int, MAX_N](fill=0)
            var current = InlineArray[Int, MAX_N](fill=0)
            var first = 0
            var last = 0
            level[source] = 0
            breadth[last] = source
            last += 1
            while first < last:
                let u = breadth[first]
                first += 1
                for edge in range(2 * m):
                    if network.from_vertex[edge] != u or network.capacity[edge] <= 0:
                        continue
                    let v = network.to_vertex[edge]
                    if dist[v] == dist[u] + network.cost[edge] and level[v] < 0:
                        level[v] = level[u] + 1
                        breadth[last] = v
                        last += 1
            if level[sink] < 0:
                break
            let amount = network.send_tight_level_flow(source, sink, flow_limit - total_flow,
                2 * m, dist, level, mut current)
            if amount == 0:
                break
            total_flow += amount
            total_cost += amount * dist[sink]
    let flow_bits = UInt64(total_flow)
    let cost_bits = UInt64(total_cost)
    for i in range(8):
        output[i] = UInt8((flow_bits >> (8 * i)) & 0xFF)
        output[8 + i] = UInt8((cost_bits >> (8 * i)) & 0xFF)
    return 16
