# Bounded clean-room tied-list maximum-cardinality popular matching.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime A_MAX = 4
comptime P_MAX = 4
comptime R_MAX = 8
comptime NODE_MAX = 12
comptime INPUT_MAX = 52

fn mp_augment(a: Int, right_count: Int, edges: List[Bool], mut left: List[Int],
              mut right: List[Int], mut seen: List[Bool]) -> Bool:
    for p in range(right_count):
        if not edges[a * R_MAX + p] or seen[p]: continue
        seen[p] = True
        let previous = right[p]
        if previous < 0 or mp_augment(previous, right_count, edges, mut left, mut right, mut seen):
            right[p] = a
            left[a] = p
            return True
    return False

fn mp_maximum(applicants: Int, right_count: Int, edges: List[Bool], initial: List[Int],
              mut left: List[Int], mut right: List[Int]) -> Bool:
    for a in range(A_MAX): left[a] = initial[a]
    for p in range(R_MAX): right[p] = -1
    for a in range(applicants):
        if left[a] >= 0:
            let p = left[a]
            if p >= right_count or right[p] >= 0 or not edges[a * R_MAX + p]: return False
            right[p] = a
    while True:
        var changed = False
        for a in range(applicants):
            if left[a] < 0:
                var seen = List[Bool](length=R_MAX, fill=False)
                if mp_augment(a, right_count, edges, mut left, mut right, mut seen): changed = True
        if not changed: return True
    return False

fn mp_solve(applicants: Int, posts: Int, ranks: List[Int], max_rank: List[Int]) -> Int64:
    let right_count = posts + applicants
    var first_edges = List[Bool](length=A_MAX * R_MAX, fill=False)
    for a in range(applicants):
        for p in range(posts): first_edges[a * R_MAX + p] = ranks[a * P_MAX + p] == 1
    var initial = List[Int](length=A_MAX, fill=-1)
    var first_left = List[Int](length=A_MAX, fill=-1)
    var first_right = List[Int](length=R_MAX, fill=-1)
    if not mp_maximum(applicants, right_count, first_edges, initial, mut first_left, mut first_right): return 0
    var first_size = 0
    for a in range(applicants):
        if first_left[a] >= 0: first_size += 1

    var state = List[Int](length=NODE_MAX, fill=-1)
    var queue = List[Int](length=NODE_MAX, fill=0)
    var tail = 0
    for a in range(applicants):
        if first_left[a] < 0:
            state[a] = 0
            queue[tail] = a
            tail += 1
    for p in range(posts):
        if first_right[p] < 0:
            let node = applicants + p
            state[node] = 0
            queue[tail] = node
            tail += 1
    for a in range(applicants):
        let node = applicants + posts + a
        state[node] = 0
        queue[tail] = node
        tail += 1
    var head = 0
    while head < tail:
        let node = queue[head]
        head += 1
        if node < applicants:
            let a = node
            if state[node] == 0:
                for p in range(posts):
                    if ranks[a * P_MAX + p] == 1 and first_left[a] != p:
                        let target = applicants + p
                        if state[target] < 0:
                            state[target] = 1
                            queue[tail] = target
                            tail += 1
            elif first_left[a] >= 0:
                let target = applicants + first_left[a]
                if state[target] < 0:
                    state[target] = 0
                    queue[tail] = target
                    tail += 1
        else:
            let p = node - applicants
            if p < posts:
                if state[node] == 0:
                    for a in range(applicants):
                        if ranks[a * P_MAX + p] == 1 and first_left[a] != p and state[a] < 0:
                            state[a] = 1
                            queue[tail] = a
                            tail += 1
                elif first_right[p] >= 0:
                    let target = first_right[p]
                    if state[target] < 0:
                        state[target] = 0
                        queue[tail] = target
                        tail += 1

    var classes = List[Int](length=NODE_MAX, fill=2)
    for i in range(applicants + right_count):
        if state[i] >= 0: classes[i] = state[i]
    var allowed = List[Bool](length=A_MAX * R_MAX, fill=False)
    for a in range(applicants):
        var best_even = posts + 1
        for p in range(posts):
            let rank = ranks[a * P_MAX + p]
            if rank > 0 and classes[applicants + p] == 0: best_even = min(best_even, rank)
        let last_rank = max_rank[a] + 1
        if classes[applicants + posts + a] == 0: best_even = min(best_even, last_rank)
        for p in range(posts):
            let rank = ranks[a * P_MAX + p]
            if rank != 1 and not (rank > 0 and rank == best_even and classes[applicants + p] == 0): continue
            let ac = classes[a]
            let pc = classes[applicants + p]
            if (ac == 1 and (pc == 1 or pc == 2)) or (ac == 2 and pc == 1): continue
            allowed[a * R_MAX + p] = True
        if last_rank == best_even and classes[applicants + posts + a] == 0:
            let p = posts + a
            let ac = classes[a]
            let pc = classes[applicants + p]
            if not ((ac == 1 and (pc == 1 or pc == 2)) or (ac == 2 and pc == 1)):
                allowed[a * R_MAX + p] = True
    for a in range(applicants):
        if first_left[a] >= 0 and not allowed[a * R_MAX + first_left[a]]: return 0

    var popular_left = List[Int](length=A_MAX, fill=-1)
    var temp_right = List[Int](length=R_MAX, fill=-1)
    if not mp_maximum(applicants, right_count, allowed, first_left, mut popular_left, mut temp_right): return 0
    var rank_one = 0
    for a in range(applicants):
        if popular_left[a] < 0: return 0
        let p = popular_left[a]
        if p < posts and ranks[a * P_MAX + p] == 1: rank_one += 1
    if rank_one != first_size: return 0

    var real_edges = List[Bool](length=A_MAX * R_MAX, fill=False)
    var initial_real = List[Int](length=A_MAX, fill=-1)
    for a in range(applicants):
        if popular_left[a] < posts: initial_real[a] = popular_left[a]
        for p in range(posts): real_edges[a * R_MAX + p] = allowed[a * R_MAX + p]
    var real_left = List[Int](length=A_MAX, fill=-1)
    if not mp_maximum(applicants, right_count, real_edges, initial_real, mut real_left, mut temp_right): return 0
    rank_one = 0
    for a in range(applicants):
        let p = real_left[a]
        if p >= 0 and p < posts and ranks[a * P_MAX + p] == 1: rank_one += 1
    if rank_one != first_size: return 0
    var final_left = List[Int](length=A_MAX, fill=-1)
    if not mp_maximum(applicants, right_count, allowed, real_left, mut final_left, mut temp_right): return 0
    var result = 0
    rank_one = 0
    for a in range(applicants):
        if final_left[a] < 0: return 0
        let p = final_left[a]
        if p < posts:
            result += 1
            if ranks[a * P_MAX + p] == 1: rank_one += 1
    if rank_one != first_size: return 0
    return result

@export("ties_maximum_cardinality_popular_matching")
fn ties_maximum_cardinality_popular_matching(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(INPUT_MAX): return -1
    let av = input[0]
    let pv = input[1]
    let ev = input[2]
    if av < 1 or av > A_MAX or pv < 1 or pv > P_MAX or ev < av or ev > av * pv: return -1
    let applicants = Int(av)
    let posts = Int(pv)
    let edge_count = Int(ev)
    if length != c_size_t(3 + 3 * edge_count): return -1
    var ranks = List[Int](length=A_MAX * P_MAX, fill=0)
    var max_rank = List[Int](length=A_MAX, fill=0)
    var cursor = 3
    for _ in range(edge_count):
        let a64 = input[cursor]
        let p64 = input[cursor + 1]
        let r64 = input[cursor + 2]
        cursor += 3
        if a64 < 0 or a64 >= av or p64 < 0 or p64 >= pv or r64 < 1 or r64 > pv: return -1
        let a = Int(a64)
        let p = Int(p64)
        let rank = Int(r64)
        if ranks[a * P_MAX + p] != 0: return -1
        ranks[a * P_MAX + p] = rank
        max_rank[a] = max(max_rank[a], rank)
    var has_tie = False
    for a in range(applicants):
        if max_rank[a] == 0: return -1
        var counts = List[Int](length=P_MAX + 1, fill=0)
        for p in range(posts):
            let rank = ranks[a * P_MAX + p]
            if rank > 0: counts[rank] += 1
        for rank in range(1, max_rank[a] + 1):
            if counts[rank] == 0: return -1
            if counts[rank] > 1: has_tie = True
    if not has_tie: return -1
    return mp_solve(applicants, posts, ranks, max_rank)
