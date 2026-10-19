from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime INF_DIST = 1_000_000

fn hk_dfs(left: Int, right_count: Int, adjacency: List[Bool], mut distance: List[Int], nil_distance: Int, mut pair_left: List[Int], mut pair_right: List[Int]) -> Bool:
    for right in range(right_count):
        if not adjacency[left * 64 + right]: continue
        let mate = pair_right[right]
        if mate < 0:
            if distance[left] + 1 != nil_distance: continue
            pair_left[left] = right; pair_right[right] = left
            return True
        if distance[mate] == distance[left] + 1 and hk_dfs(mate, right_count, adjacency, distance, nil_distance, pair_left, pair_right):
            pair_left[left] = right; pair_right[right] = left
            return True
    distance[left] = INF_DIST
    return False

fn hk_bfs(left_count: Int, right_count: Int, adjacency: List[Bool], pair_right: List[Int], mut distance: List[Int]) -> Int:
    var queue = List[Int](capacity=64); var head = 0
    for l in range(left_count):
        if distance[l] == 0: queue.append(l)
    var nil_distance = INF_DIST
    while head < len(queue):
        let left = queue[head]; head += 1
        if distance[left] + 1 > nil_distance: continue
        for right in range(right_count):
            if not adjacency[left * 64 + right]: continue
            let mate = pair_right[right]
            if mate < 0: nil_distance = min(nil_distance, distance[left] + 1)
            elif distance[mate] < 0: distance[mate] = distance[left] + 1; queue.append(mate)
    return nil_distance

@export("bipartite_matching_hopcroft_karp")
fn bipartite_matching_hopcroft_karp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let lv = input[0]; let rv = input[1]; let ev = input[2]
    if lv < 0 or lv > 64 or rv < 0 or rv > 64 or ev < 0 or ev > 4096 or length != c_size_t(3 + 2 * ev): return -1
    let lcount = Int(lv); let rcount = Int(rv); var adjacency = List[Bool](capacity=4096)
    for _ in range(4096): adjacency.append(False)
    for i in range(Int(ev)):
        let l = input[3 + 2 * i]; let r = input[4 + 2 * i]
        if l < 0 or l >= lv or r < 0 or r >= rv: return -1
        adjacency[Int(l) * 64 + Int(r)] = True
    var pair_left = List[Int](capacity=64); var pair_right = List[Int](capacity=64); var distance = List[Int](capacity=64)
    for _ in range(64): pair_left.append(-1); pair_right.append(-1); distance.append(-1)
    var matching = 0
    while True:
        for l in range(lcount): distance[l] = 0 if pair_left[l] < 0 else -1
        let nil_distance = hk_bfs(lcount, rcount, adjacency, pair_right, distance)
        if nil_distance == INF_DIST: break
        for l in range(lcount):
            if pair_left[l] < 0 and hk_dfs(l, rcount, adjacency, distance, nil_distance, pair_left, pair_right): matching += 1
    return Int64(matching)
