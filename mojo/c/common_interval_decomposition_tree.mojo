from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MAX_N = 48
alias MAX_NODES = 2 * MAX_N - 1
alias GRID = MAX_N * MAX_N

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn intervals_overlap(left_a: Int, right_a: Int, left_b: Int, right_b: Int) -> Bool:
    return (left_a < left_b and left_b <= right_a and right_a < right_b) or (
        left_b < left_a and left_a <= right_b and right_b < right_a
    )

@export("common_interval_decomposition_tree")
fn common_interval_decomposition_tree(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1 + MAX_N:
        return -1
    let n_value = input[0]
    if n_value < 1 or n_value > MAX_N:
        return -1
    let n = Int(n_value)
    if length != c_size_t(n + 1):
        return -1

    var seen = InlineArray[Bool, MAX_N]()
    for i in range(n):
        let value = input[i + 1]
        if value < 0 or value >= n_value:
            return -1
        if seen[Int(value)]:
            return -1
        seen[Int(value)] = True

    var connected = InlineArray[Bool, GRID]()
    var strong = InlineArray[Bool, GRID]()
    for left in range(n):
        var minimum = n_value
        var maximum: Int64 = -1
        for right in range(left, n):
            let value = input[right + 1]
            minimum = min(minimum, value)
            maximum = max(maximum, value)
            let slot = left * MAX_N + right
            if maximum - minimum == Int64(right - left):
                connected[slot] = True
                strong[slot] = True

    for left_a in range(n):
        for right_a in range(left_a, n):
            let slot_a = left_a * MAX_N + right_a
            if not connected[slot_a]:
                continue
            for left_b in range(n):
                for right_b in range(left_b, n):
                    let slot_b = left_b * MAX_N + right_b
                    if slot_b <= slot_a or not connected[slot_b]:
                        continue
                    if intervals_overlap(left_a, right_a, left_b, right_b):
                        strong[slot_a] = False
                        strong[slot_b] = False

    var node_left = InlineArray[Int, MAX_NODES]()
    var node_right = InlineArray[Int, MAX_NODES]()
    var parent = InlineArray[Int, MAX_NODES]()
    var node_type = InlineArray[Int, MAX_NODES]()
    for node in range(MAX_NODES):
        parent[node] = -1
    var node_count = 0
    for span in range(n, 0, -1):
        for left in range(n - span + 1):
            let right = left + span - 1
            if not strong[left * MAX_N + right]:
                continue
            node_left[node_count] = left
            node_right[node_count] = right
            node_count += 1
    if node_count == 0 or node_count > MAX_NODES:
        return -1

    for node in range(node_count):
        let node_span = node_right[node] - node_left[node] + 1
        var best_span = n + 1
        for candidate in range(node_count):
            let candidate_span = node_right[candidate] - node_left[candidate] + 1
            if candidate_span > node_span and candidate_span < best_span and (
                node_left[candidate] <= node_left[node]
                and node_right[node] <= node_right[candidate]
            ):
                parent[node] = candidate
                best_span = candidate_span

    for node in range(node_count):
        var children = InlineArray[Int, MAX_N]()
        var child_count = 0
        for child in range(node_count):
            if parent[child] != node:
                continue
            var at = child_count
            while at > 0 and node_left[children[at - 1]] > node_left[child]:
                children[at] = children[at - 1]
                at -= 1
            children[at] = child
            child_count += 1

        for first in range(child_count):
            for last in range(first, child_count):
                let left = node_left[children[first]]
                let right = node_right[children[last]]
                var minimum = n_value
                var maximum: Int64 = -1
                for position in range(left, right + 1):
                    let value = input[position + 1]
                    minimum = min(minimum, value)
                    maximum = max(maximum, value)
                if maximum - minimum != Int64(right - left):
                    node_type[node] = 1
                    break
            if node_type[node] != 0:
                break

    let output_bytes = (1 + 4 * node_count) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    store_i64_le(output, 0, Int64(node_count))
    for node in range(node_count):
        let offset = 8 + 32 * node
        store_i64_le(output, offset, Int64(parent[node]))
        store_i64_le(output, offset + 8, Int64(node_left[node]))
        store_i64_le(output, offset + 16, Int64(node_right[node]))
        store_i64_le(output, offset + 24, Int64(node_type[node]))
    return Int64(output_bytes)
