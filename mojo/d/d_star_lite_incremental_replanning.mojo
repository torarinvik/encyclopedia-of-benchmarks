from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime DSL_MAX_N = 16
comptime DSL_MAX_E = 48
comptime DSL_MAX_Q = 16
comptime DSL_MAX_INPUT = 198
comptime DSL_MAX_PARSEABLE = 199
comptime DSL_INF = Int64(1_000_000_000)

fn dsl_manhattan(left: Int, right: Int, width: Int) -> Int64:
    let left_row = left // width
    let right_row = right // width
    let left_col = left % width
    let right_col = right % width
    let row_delta = if left_row > right_row: left_row - right_row else: right_row - left_row
    let col_delta = if left_col > right_col: left_col - right_col else: right_col - left_col
    return Int64(row_delta + col_delta)

fn dsl_key1(g: InlineArray[Int64, DSL_MAX_N], rhs: InlineArray[Int64, DSL_MAX_N],
            node: Int, start: Int, width: Int, km: Int64) -> Int64:
    let base = if g[node] < rhs[node]: g[node] else: rhs[node]
    if base >= DSL_INF: return DSL_INF
    return base + dsl_manhattan(start, node, width) + km

fn dsl_pair_less(left_first: Int64, left_second: Int64,
                 right_first: Int64, right_second: Int64) -> Bool:
    return left_first < right_first or (left_first == right_first and left_second < right_second)

fn dsl_update_vertex(inout g: InlineArray[Int64, DSL_MAX_N],
                     inout rhs: InlineArray[Int64, DSL_MAX_N],
                     inout in_open: InlineArray[Bool, DSL_MAX_N],
                     inout queue_first: InlineArray[Int64, DSL_MAX_N],
                     inout queue_second: InlineArray[Int64, DSL_MAX_N],
                     edge_from: InlineArray[Int, DSL_MAX_E],
                     edge_to: InlineArray[Int, DSL_MAX_E],
                     edge_cost: InlineArray[Int64, DSL_MAX_E],
                     edge_count: Int, node: Int, goal: Int, start: Int,
                     width: Int, km: Int64):
    if node != goal:
        var best = DSL_INF
        for edge in range(edge_count):
            if edge_from[edge] == node and g[edge_to[edge]] < DSL_INF:
                let candidate = edge_cost[edge] + g[edge_to[edge]]
                if candidate < best: best = candidate
        rhs[node] = best
    in_open[node] = False
    if g[node] != rhs[node]:
        in_open[node] = True
        queue_first[node] = dsl_key1(g, rhs, node, start, width, km)
        queue_second[node] = if g[node] < rhs[node]: g[node] else: rhs[node]

fn dsl_execute(values: InlineArray[Int64, DSL_MAX_PARSEABLE], length: Int) -> Int64:
    if length < 6 or length > DSL_MAX_PARSEABLE: return -1
    let height_value = values[0]
    let width_value = values[1]
    let edge_value = values[2]
    let query_value = values[3]
    if height_value < 1 or height_value > 4 or width_value < 1 or width_value > 4: return -1
    let height = Int(height_value)
    let width = Int(width_value)
    let node_count = height * width
    if node_count < 2 or node_count > DSL_MAX_N: return -1
    if edge_value < 0 or edge_value > DSL_MAX_E or query_value < 0 or query_value > DSL_MAX_Q: return -1
    let edge_count = Int(edge_value)
    let query_count = Int(query_value)
    let max_edges = 2 * (height * (width - 1) + width * (height - 1))
    if edge_count > max_edges or length != 6 + 3 * edge_count + 3 * query_count or length > DSL_MAX_INPUT: return -1
    let start_value = values[4]
    let goal_value = values[5]
    if start_value < 0 or goal_value < 0 or start_value >= node_count or goal_value >= node_count: return -1

    var edge_from = InlineArray[Int, DSL_MAX_E](fill=0)
    var edge_to = InlineArray[Int, DSL_MAX_E](fill=0)
    var edge_cost = InlineArray[Int64, DSL_MAX_E](fill=0)
    for edge in range(edge_count):
        let base = 6 + 3 * edge
        let from_value = values[base]
        let to_value = values[base + 1]
        let cost = values[base + 2]
        if from_value < 0 or to_value < 0 or from_value >= node_count or to_value >= node_count: return -1
        if cost < 1 or cost > 9: return -1
        let from_node = Int(from_value)
        let to_node = Int(to_value)
        if dsl_manhattan(from_node, to_node, width) != 1: return -1
        for previous in range(edge):
            if edge_from[previous] == from_node and edge_to[previous] == to_node: return -1
        edge_from[edge] = from_node
        edge_to[edge] = to_node
        edge_cost[edge] = cost

    var event_start = InlineArray[Int, DSL_MAX_Q](fill=0)
    var event_edge = InlineArray[Int, DSL_MAX_Q](fill=0)
    var event_cost = InlineArray[Int64, DSL_MAX_Q](fill=0)
    for event in range(query_count):
        let base = 6 + 3 * edge_count + 3 * event
        let next_start = values[base]
        let edge_index = values[base + 1]
        let cost = values[base + 2]
        if next_start < 0 or next_start >= node_count or edge_index < 0 or edge_index >= edge_count: return -1
        if cost < 1 or cost > 9: return -1
        event_start[event] = Int(next_start)
        event_edge[event] = Int(edge_index)
        event_cost[event] = cost

    var g = InlineArray[Int64, DSL_MAX_N](fill=0)
    var rhs = InlineArray[Int64, DSL_MAX_N](fill=0)
    var in_open = InlineArray[Bool, DSL_MAX_N](fill=False)
    var queue_first = InlineArray[Int64, DSL_MAX_N](fill=0)
    var queue_second = InlineArray[Int64, DSL_MAX_N](fill=0)
    for node in range(node_count):
        g[node] = DSL_INF
        rhs[node] = DSL_INF
    var start = Int(start_value)
    let goal = Int(goal_value)
    var last_start = start
    var km: Int64 = 0
    rhs[goal] = 0
    in_open[goal] = True
    queue_first[goal] = dsl_key1(g, rhs, goal, start, width, km)
    queue_second[goal] = 0

    var checksum: Int64 = 0
    for event in range(query_count):
        start = event_start[event]
        km += dsl_manhattan(last_start, start, width)
        last_start = start
        edge_cost[event_edge[event]] = event_cost[event]
        dsl_update_vertex(g, rhs, in_open, queue_first, queue_second,
                          edge_from, edge_to, edge_cost, edge_count,
                          edge_from[event_edge[event]], goal, start, width, km)

        while True:
            var selected = node_count
            for candidate_node in range(node_count):
                if in_open[candidate_node]:
                    if selected == node_count:
                        selected = candidate_node
                    elif dsl_pair_less(queue_first[candidate_node], queue_second[candidate_node],
                                       queue_first[selected], queue_second[selected]) or
                         (queue_first[candidate_node] == queue_first[selected] and
                          queue_second[candidate_node] == queue_second[selected] and candidate_node < selected):
                        selected = candidate_node
            if selected == node_count: break
            let start_key_first = dsl_key1(g, rhs, start, start, width, km)
            let start_key_second = if g[start] < rhs[start]: g[start] else: rhs[start]
            let top_before_start = dsl_pair_less(queue_first[selected], queue_second[selected], start_key_first, start_key_second)
            if not top_before_start and rhs[start] == g[start]: break

            let old_first = queue_first[selected]
            let old_second = queue_second[selected]
            in_open[selected] = False
            let new_first = dsl_key1(g, rhs, selected, start, width, km)
            let new_second = if g[selected] < rhs[selected]: g[selected] else: rhs[selected]
            if dsl_pair_less(old_first, old_second, new_first, new_second):
                in_open[selected] = True
                queue_first[selected] = new_first
                queue_second[selected] = new_second
            elif g[selected] > rhs[selected]:
                g[selected] = rhs[selected]
                for edge in range(edge_count):
                    if edge_to[edge] == selected:
                        dsl_update_vertex(g, rhs, in_open, queue_first, queue_second,
                                          edge_from, edge_to, edge_cost, edge_count,
                                          edge_from[edge], goal, start, width, km)
            else:
                g[selected] = DSL_INF
                dsl_update_vertex(g, rhs, in_open, queue_first, queue_second,
                                  edge_from, edge_to, edge_cost, edge_count,
                                  selected, goal, start, width, km)
                for edge in range(edge_count):
                    if edge_to[edge] == selected:
                        dsl_update_vertex(g, rhs, in_open, queue_first, queue_second,
                                          edge_from, edge_to, edge_cost, edge_count,
                                          edge_from[edge], goal, start, width, km)

        var next_code: Int64 = 0
        if start != goal and g[start] < DSL_INF:
            var best = DSL_INF
            var best_node = node_count
            for edge in range(edge_count):
                if edge_from[edge] == start and g[edge_to[edge]] < DSL_INF:
                    let candidate = edge_cost[edge] + g[edge_to[edge]]
                    if candidate < best or (candidate == best and edge_to[edge] < best_node):
                        best = candidate
                        best_node = edge_to[edge]
            if best == g[start] and best_node < node_count: next_code = Int64(best_node + 1)
        let distance_code = if g[start] < DSL_INF: g[start] else: Int64(136)
        checksum += Int64(event + 1) * (distance_code + 1) * (next_code + 1)
    return checksum

@export("d_star_lite_incremental_replanning")
fn d_star_lite_incremental_replanning(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(6) or length > c_size_t(DSL_MAX_PARSEABLE): return -1
    let input_length = Int(length)
    var values = InlineArray[Int64, DSL_MAX_PARSEABLE](fill=0)
    for index in range(input_length): values[index] = input[index]
    return dsl_execute(values, input_length)
