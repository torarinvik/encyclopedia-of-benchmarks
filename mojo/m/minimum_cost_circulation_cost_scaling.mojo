from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

from std.collections import InlineArray

@export("minimum_cost_circulation_cost_scaling")
fn minimum_cost_circulation_cost_scaling(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 43:
        return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 0 or input[1] > 10:
        return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if length != c_size_t(2 + 4 * m):
        return -1

    var edge_from = InlineArray[Int, 20](fill=0)
    var edge_to = InlineArray[Int, 20](fill=0)
    var reverse = InlineArray[Int, 20](fill=0)
    var capacity = InlineArray[Int64, 20](fill=0)
    var edge_cost = InlineArray[Int64, 20](fill=0)
    var max_scaled_cost: Int64 = 0
    for index in range(m):
        let offset = 2 + 4 * index
        let from_value = input[offset]
        let to_value = input[offset + 1]
        let original_capacity = input[offset + 2]
        let cost = input[offset + 3]
        if from_value < 0 or from_value >= input[0] or to_value < 0 or to_value >= input[0]
            or original_capacity < 0 or original_capacity > 2 or cost < -4 or cost > 4:
            return -1
        let from = Int(from_value)
        let to = Int(to_value)
        let scaled_cost = cost * Int64(n + 1)
        let forward = 2 * index
        let backward = forward + 1
        edge_from[forward] = from
        edge_to[forward] = to
        reverse[forward] = backward
        capacity[forward] = original_capacity
        edge_cost[forward] = scaled_cost
        edge_from[backward] = to
        edge_to[backward] = from
        reverse[backward] = forward
        capacity[backward] = 0
        edge_cost[backward] = -scaled_cost
        let magnitude = if scaled_cost < 0 { -scaled_cost } else { scaled_cost }
        if magnitude > max_scaled_cost:
            max_scaled_cost = magnitude

    var epsilon: Int64 = 1
    while epsilon < max_scaled_cost:
        epsilon *= 2
    var price = InlineArray[Int64, 8](fill=0)
    let arc_count = 2 * m
    while epsilon > 1:
        epsilon /= 2
        var excess = InlineArray[Int64, 8](fill=0)
        for edge_index in range(arc_count):
            if capacity[edge_index] <= 0:
                continue
            let from = edge_from[edge_index]
            let to = edge_to[edge_index]
            let reduced_cost = edge_cost[edge_index] + price[from] - price[to]
            if reduced_cost < 0:
                let amount = capacity[edge_index]
                capacity[edge_index] = 0
                capacity[reverse[edge_index]] += amount
                excess[from] -= amount
                excess[to] += amount

        var queue = InlineArray[Int, 8](fill=0)
        var queued = InlineArray[Bool, 8](fill=False)
        var head = 0
        var tail = 0
        var queue_count = 0
        for vertex in range(n):
            if excess[vertex] > 0:
                queue[tail] = vertex
                tail = (tail + 1) % n
                queue_count += 1
                queued[vertex] = True

        while queue_count > 0:
            let vertex = queue[head]
            head = (head + 1) % n
            queue_count -= 1
            queued[vertex] = False
            while excess[vertex] > 0:
                var admissible = 20
                for edge_index in range(arc_count):
                    if edge_from[edge_index] != vertex or edge_to[edge_index] == vertex
                        or capacity[edge_index] <= 0:
                        continue
                    let to = edge_to[edge_index]
                    if edge_cost[edge_index] + price[vertex] - price[to] < 0:
                        admissible = edge_index
                        break

                if admissible < 20:
                    let to = edge_to[admissible]
                    let reverse_index = reverse[admissible]
                    let amount = if excess[vertex] < capacity[admissible]
                        { excess[vertex] } else { capacity[admissible] }
                    capacity[admissible] -= amount
                    capacity[reverse_index] += amount
                    let old_excess = excess[to]
                    excess[vertex] -= amount
                    excess[to] += amount
                    if old_excess <= 0 and excess[to] > 0 and not queued[to]:
                        queue[tail] = to
                        tail = (tail + 1) % n
                        queue_count += 1
                        queued[to] = True
                else:
                    var has_exit = False
                    var best_price: Int64 = 0
                    for edge_index in range(arc_count):
                        if edge_from[edge_index] != vertex or capacity[edge_index] <= 0:
                            continue
                        let to = edge_to[edge_index]
                        let candidate = price[to] - edge_cost[edge_index] - epsilon
                        if not has_exit or candidate > best_price:
                            has_exit = True
                            best_price = candidate
                    if not has_exit:
                        return -1
                    price[vertex] = best_price

        for vertex in range(n):
            if excess[vertex] != 0:
                return -1

    var total_cost: Int64 = 0
    for index in range(m):
        let original_capacity = input[2 + 4 * index + 2]
        let original_cost = input[2 + 4 * index + 3]
        let flow = original_capacity - capacity[2 * index]
        total_cost += flow * original_cost
    return total_cost + 81
