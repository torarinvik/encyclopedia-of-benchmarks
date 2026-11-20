from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn dm_augment(left: Int, right_count: Int, adjacency: List[UInt32],
              mut seen: List[Bool], mut match_right: List[Int]) -> Bool:
    for right in range(right_count):
        let bit = UInt32(1) << UInt32(right)
        if adjacency[left] & bit == 0 or seen[right]: continue
        seen[right] = True
        let mate = match_right[right]
        if mate < 0 or dm_augment(mate, right_count, adjacency, seen, match_right):
            match_right[right] = left
            return True
    return False

fn dm_matching(left_count: Int, right_count: Int, adjacency: List[UInt32],
               mut match_left: List[Int], mut match_right: List[Int]) -> Int:
    for right in range(6): match_right[right] = -1
    var size = 0
    for left in range(left_count):
        var seen = List[Bool](length=6, fill=False)
        if dm_augment(left, right_count, adjacency, seen, match_right): size += 1
    for left in range(6): match_left[left] = -1
    for right in range(right_count):
        if match_right[right] >= 0: match_left[match_right[right]] = right
    return size

@export("dulmage_mendelsohn_decomposition")
fn dulmage_mendelsohn_decomposition(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 76: return -1
    let left64 = input[0]
    let right64 = input[1]
    let edges64 = input[2]
    if left64 < 0 or left64 > 6 or right64 < 0 or right64 > 6 or left64 + right64 < 1 or
       edges64 < 0 or edges64 > 36 or edges64 > left64 * right64: return -1
    let left_count = Int(left64)
    let right_count = Int(right64)
    let total = left_count + right_count
    let edge_count = Int(edges64)
    if length != c_size_t(3 + 2 * edge_count): return -1
    var adjacency = List[UInt32](length=6, fill=0)
    var global = List[UInt32](length=12, fill=0)
    for edge in range(edge_count):
        let u64 = input[3 + 2 * edge]
        let v64 = input[4 + 2 * edge]
        if u64 < 0 or u64 >= left64 or v64 < 0 or v64 >= right64: return -1
        let u = Int(u64)
        let v = Int(v64)
        let right_vertex = left_count + v
        let bit = UInt32(1) << UInt32(v)
        if adjacency[u] & bit != 0: return -1
        adjacency[u] |= bit
        global[u] |= UInt32(1) << UInt32(right_vertex)
        global[right_vertex] |= UInt32(1) << UInt32(u)

    var match_left = List[Int](length=6, fill=-1)
    var match_right = List[Int](length=6, fill=-1)
    let matching_size = dm_matching(left_count, right_count, adjacency, match_left, match_right)
    var seen = List[Bool](length=24, fill=False)
    var queue = List[Int](capacity=24)
    for left in range(left_count):
        if match_left[left] < 0:
            let state = 2 * left
            seen[state] = True
            queue.append(state)
    for right in range(right_count):
        if match_right[right] < 0:
            let state = 2 * (left_count + right)
            seen[state] = True
            queue.append(state)
    var head = 0
    while head < len(queue):
        let state = queue[head]
        head += 1
        let vertex = state // 2
        let parity = state % 2
        for neighbor in range(total):
            if global[vertex] & (UInt32(1) << UInt32(neighbor)) == 0: continue
            let matched = match_left[vertex] == neighbor - left_count if vertex < left_count else match_right[vertex - left_count] == neighbor
            if (parity == 0 and matched) or (parity == 1 and not matched): continue
            let next_state = 2 * neighbor + 1 - parity
            if not seen[next_state]:
                seen[next_state] = True
                queue.append(next_state)

    var packed: UInt64 = UInt64(matching_size) << 32
    for vertex in range(total):
        let code = 0 if seen[2 * vertex] else (1 if seen[2 * vertex + 1] else 2)
        packed |= UInt64(code) << UInt64(2 * vertex)
    return Int64(packed)
