from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_SIDE = 8
comptime MAX_PARSEABLE_INPUT = 11

fn bvc_augment_left(left: Int, left_count: Int, right_count: Int,
    rows: List[Int], states: List[Int], mut match_right: List[Int], mut seen: List[Bool]) -> Bool:
    for right in range(right_count):
        if (rows[left] & (1 << right)) == 0 or seen[right] or states[left_count + right] != -1: continue
        seen[right] = True
        let owner = match_right[right]
        if owner < 0 or bvc_augment_left(owner, left_count, right_count, rows, states, match_right, seen):
            match_right[right] = left
            return True
    return False

fn bvc_maximum_matching(left_count: Int, right_count: Int,
    rows: List[Int], states: List[Int], mut match_right: List[Int]) -> Int:
    for right in range(right_count): match_right[right] = -1
    var size = 0
    for left in range(left_count):
        if states[left] != -1: continue
        var seen = List[Bool](capacity=MAX_SIDE)
        for _ in range(MAX_SIDE): seen.append(False)
        if bvc_augment_left(left, left_count, right_count, rows, states, match_right, seen): size += 1
    return size

fn bvc_alternating_cover(left_count: Int, right_count: Int,
    rows: List[Int], match_right: List[Int]) -> Int64:
    var matched_left = List[Bool](capacity=MAX_SIDE)
    var reached_left = List[Bool](capacity=MAX_SIDE)
    var reached_right = List[Bool](capacity=MAX_SIDE)
    var queue = List[Int](capacity=MAX_SIDE)
    for _ in range(MAX_SIDE):
        matched_left.append(False)
        reached_left.append(False)
        reached_right.append(False)
        queue.append(0)
    for right in range(right_count):
        if match_right[right] >= 0: matched_left[match_right[right]] = True
    var head = 0
    var tail = 0
    for left in range(left_count):
        if not matched_left[left]:
            reached_left[left] = True
            queue[tail] = left
            tail += 1
    while head < tail:
        let left = queue[head]
        head += 1
        for right in range(right_count):
            if (rows[left] & (1 << right)) == 0 or reached_right[right] or match_right[right] < 0: continue
            reached_right[right] = True
            let owner = match_right[right]
            if not reached_left[owner]:
                reached_left[owner] = True
                queue[tail] = owner
                tail += 1
    var result: Int64 = 0
    for left in range(left_count):
        if not reached_left[left]: result |= Int64(1) << left
    for right in range(right_count):
        if reached_right[right]: result |= Int64(1) << (left_count + right)
    return result

fn bvc_bit_count(value_input: Int64) -> Int:
    var value = value_input
    var count = 0
    while value != 0:
        count += Int(value & 1)
        value >>= 1
    return count

fn bvc_minimum_completion_size(left_count: Int, right_count: Int,
    rows: List[Int], input_states: List[Int]) -> Int:
    let total = left_count + right_count
    var states = List[Int](capacity=2 * MAX_SIDE)
    for i in range(total): states.append(input_states[i])
    var changed = True
    while changed:
        changed = False
        for left in range(left_count):
            for right in range(right_count):
                if (rows[left] & (1 << right)) == 0: continue
                let right_vertex = left_count + right
                if states[left] == 0 and states[right_vertex] == 0: return -1
                if states[left] == 0 and states[right_vertex] == -1:
                    states[right_vertex] = 1
                    changed = True
                elif states[right_vertex] == 0 and states[left] == -1:
                    states[left] = 1
                    changed = True
    var forced_in = 0
    for i in range(total):
        if states[i] == 1: forced_in += 1
    var residual_match = List[Int](capacity=MAX_SIDE)
    for _ in range(MAX_SIDE): residual_match.append(-1)
    return forced_in + bvc_maximum_matching(left_count, right_count, rows, states, residual_match)

fn bvc_canonical_cover(left_count: Int, right_count: Int,
    rows: List[Int], optimum: Int) -> Int64:
    let total = left_count + right_count
    var states = List[Int](capacity=2 * MAX_SIDE)
    for _ in range(total): states.append(-1)
    for vertex in range(total):
        states[vertex] = 0
        if bvc_minimum_completion_size(left_count, right_count, rows, states) != optimum:
            states[vertex] = 1
    var result: Int64 = 0
    for vertex in range(total):
        if states[vertex] == 1: result |= Int64(1) << vertex
    return result

@export("bipartite_minimum_vertex_cover")
fn bipartite_minimum_vertex_cover(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_PARSEABLE_INPUT: return -1
    let left_value = input[0]
    let right_value = input[1]
    if left_value < 0 or left_value > MAX_SIDE or right_value < 0 or right_value > MAX_SIDE: return -1
    let left_count = Int(left_value)
    let right_count = Int(right_value)
    if length != c_size_t(left_count + 2): return -1
    let right_domain = (1 << right_count) - 1
    var rows = List[Int](capacity=MAX_SIDE)
    for _ in range(MAX_SIDE): rows.append(0)
    for left in range(left_count):
        let row = input[2 + left]
        if row < 0 or (row & ~right_domain) != 0: return -1
        rows[left] = Int(row)
    var free_states = List[Int](capacity=2 * MAX_SIDE)
    for _ in range(2 * MAX_SIDE): free_states.append(-1)
    var match_right = List[Int](capacity=MAX_SIDE)
    for _ in range(MAX_SIDE): match_right.append(-1)
    let matching_size = bvc_maximum_matching(left_count, right_count, rows, free_states, match_right)
    let seed = bvc_alternating_cover(left_count, right_count, rows, match_right)
    let optimum = bvc_bit_count(seed)
    if optimum != matching_size: return -1
    return bvc_canonical_cover(left_count, right_count, rows, optimum)
