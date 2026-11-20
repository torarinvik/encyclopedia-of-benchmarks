from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

from std.collections import InlineArray

fn mmch_gcd(a_value: Int64, b_value: Int64) -> Int64:
    var a = a_value
    var b = b_value
    while b != 0:
        let remainder = a % b
        a = b
        b = remainder
    return a

fn mmch_compare_ratio(a_num: Int64, a_den: Int64, b_num: Int64, b_den: Int64) -> Int:
    let left = a_num * b_den
    let right = b_num * a_den
    if left < right:
        return -1
    if left > right:
        return 1
    return 0

fn mmch_reachable(n: Int, adjacency: InlineArray[Bool, 64], reverse: Bool) -> Bool:
    var seen = InlineArray[Bool, 8](fill=False)
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 1
    seen[0] = True
    queue[0] = 0
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            let slot = if reverse { v * 8 + u } else { u * 8 + v }
            if adjacency[slot] and not seen[v]:
                seen[v] = True
                queue[tail] = v
                tail += 1
    for v in range(n):
        if not seen[v]:
            return False
    return True

fn mmch_store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64) -> None:
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("minimum_mean_cycle_howard")
fn minimum_mean_cycle_howard(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 51:
        return -1
    if input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 16:
        return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if m > n * n or length != c_size_t(2 + 3 * m):
        return -1

    var edge_to = InlineArray[Int, 16](fill=0)
    var edge_weight = InlineArray[Int64, 16](fill=0)
    var outgoing = InlineArray[UInt8, 128](fill=0)
    var degree = InlineArray[Int, 8](fill=0)
    var policy = InlineArray[Int, 8](fill=0)
    var adjacent = InlineArray[Bool, 64](fill=False)
    for edge in range(m):
        let u_value = input[2 + 3 * edge]
        let v_value = input[3 + 3 * edge]
        let weight = input[4 + 3 * edge]
        if u_value < 0 or u_value >= input[0] or v_value < 0 or v_value >= input[0]
            or weight < -1000 or weight > 1000:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        let slot = u * 8 + v
        if adjacent[slot]:
            return -1
        adjacent[slot] = True
        edge_to[edge] = v
        edge_weight[edge] = weight
        outgoing[u * 16 + degree[u]] = UInt8(edge)
        if degree[u] == 0:
            policy[u] = edge
        degree[u] += 1
    if not mmch_reachable(n, adjacent, False) or not mmch_reachable(n, adjacent, True):
        return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16:
        return -2

    var policy_limit = 1
    for u in range(n):
        policy_limit *= degree[u]
    var value_num = InlineArray[Int64, 8](fill=0)
    var value_den = InlineArray[Int64, 8](fill=1)
    var bias_num = InlineArray[Int64, 8](fill=0)
    var converged = False

    for iteration in range(policy_limit):
        var assigned = InlineArray[Bool, 8](fill=False)
        for start in range(n):
            if assigned[start]:
                continue
            var local_position = InlineArray[Int, 8](fill=-1)
            var path = InlineArray[Int, 8](fill=0)
            var path_length = 0
            var vertex = start
            while not assigned[vertex] and local_position[vertex] < 0:
                local_position[vertex] = path_length
                path[path_length] = vertex
                path_length += 1
                vertex = edge_to[policy[vertex]]

            var prefix_length = path_length
            if not assigned[vertex]:
                let cycle_start = local_position[vertex]
                let cycle_length = path_length - cycle_start
                var cycle_weight: Int64 = 0
                var head_position = cycle_start
                for i in range(cycle_start, path_length):
                    let u = path[i]
                    cycle_weight += edge_weight[policy[u]]
                    if path[i] < path[head_position]:
                        head_position = i
                let absolute_weight = if cycle_weight < 0 { -cycle_weight } else { cycle_weight }
                let divisor = mmch_gcd(absolute_weight, Int64(cycle_length))
                let mean_num = cycle_weight / divisor
                let mean_den = Int64(cycle_length) / divisor
                let head = path[head_position]
                for i in range(cycle_start, path_length):
                    let u = path[i]
                    value_num[u] = mean_num
                    value_den[u] = mean_den
                    assigned[u] = True
                bias_num[head] = 0
                var current_position = head_position
                while True:
                    let previous_position = if current_position == cycle_start
                        { path_length - 1 } else { current_position - 1 }
                    let previous = path[previous_position]
                    if previous == head:
                        break
                    bias_num[previous] = edge_weight[policy[previous]] * mean_den
                        - mean_num + bias_num[path[current_position]]
                    current_position = previous_position
                prefix_length = cycle_start

            var i = prefix_length
            while i > 0:
                i -= 1
                let u = path[i]
                let successor = edge_to[policy[u]]
                value_num[u] = value_num[successor]
                value_den[u] = value_den[successor]
                bias_num[u] = edge_weight[policy[u]] * value_den[successor]
                    - value_num[successor] + bias_num[successor]
                assigned[u] = True

        var improved = InlineArray[Int, 8](fill=0)
        var changed = False
        for u in range(n):
            var best = policy[u]
            for j in range(degree[u]):
                let candidate = Int(outgoing[u * 16 + j])
                let candidate_to = edge_to[candidate]
                let best_to = edge_to[best]
                var comparison = mmch_compare_ratio(value_num[candidate_to], value_den[candidate_to],
                    value_num[best_to], value_den[best_to])
                if comparison == 0:
                    let candidate_bias = edge_weight[candidate] * value_den[candidate_to]
                        - value_num[candidate_to] + bias_num[candidate_to]
                    let best_bias = edge_weight[best] * value_den[best_to]
                        - value_num[best_to] + bias_num[best_to]
                    comparison = mmch_compare_ratio(candidate_bias, value_den[candidate_to],
                        best_bias, value_den[best_to])
                if comparison < 0:
                    best = candidate
            improved[u] = best
            if best != policy[u]:
                changed = True
        if not changed:
            converged = True
            break
        for u in range(n):
            policy[u] = improved[u]
    if not converged:
        return -1

    var best_vertex = 0
    for v in range(1, n):
        if mmch_compare_ratio(value_num[v], value_den[v],
            value_num[best_vertex], value_den[best_vertex]) < 0:
            best_vertex = v
    var answer_num = value_num[best_vertex]
    var answer_den = value_den[best_vertex]
    let absolute_num = if answer_num < 0 { -answer_num } else { answer_num }
    let divisor = mmch_gcd(absolute_num, answer_den)
    answer_num /= divisor
    answer_den /= divisor
    var staged = InlineArray[UInt8, 16](fill=0)
    mmch_store_i64_le(staged.unsafe_ptr(), 0, answer_num)
    mmch_store_i64_le(staged.unsafe_ptr(), 8, answer_den)
    for byte in range(16):
        output[byte] = staged[byte]
    return 16
