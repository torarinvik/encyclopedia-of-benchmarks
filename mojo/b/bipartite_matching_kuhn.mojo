from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn kuhn_visit(left: Int, right_count: Int, adjacency: List[Bool], mut seen: List[Bool], mut pair_right: List[Int]) -> Bool:
    for right in range(right_count):
        if not adjacency[left * 64 + right] or seen[right]: continue
        seen[right] = True
        if pair_right[right] < 0 or kuhn_visit(pair_right[right], right_count, adjacency, seen, pair_right):
            pair_right[right] = left
            return True
    return False

@export("bipartite_matching_kuhn")
fn bipartite_matching_kuhn(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3: return -1
    let lv = input[0]; let rv = input[1]; let ev = input[2]
    if lv < 0 or lv > 64 or rv < 0 or rv > 64 or ev < 0 or ev > 4096 or length != c_size_t(3 + 2 * ev): return -1
    let lcount = Int(lv); let rcount = Int(rv); var adjacency = List[Bool](capacity=4096)
    for _ in range(4096): adjacency.append(False)
    for i in range(Int(ev)):
        let l = input[3 + 2 * i]; let r = input[4 + 2 * i]
        if l < 0 or l >= lv or r < 0 or r >= rv: return -1
        adjacency[Int(l) * 64 + Int(r)] = True
    var pair_right = List[Int](capacity=64); for _ in range(64): pair_right.append(-1)
    var matching = 0
    for l in range(lcount):
        var seen = List[Bool](capacity=64); for _ in range(64): seen.append(False)
        if kuhn_visit(l, rcount, adjacency, seen, pair_right): matching += 1
    return Int64(matching)
