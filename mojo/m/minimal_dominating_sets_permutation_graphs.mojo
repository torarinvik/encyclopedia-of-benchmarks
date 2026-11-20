from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_PARSEABLE_LENGTH = 10
comptime MAX_STATES = 59049

fn graph_case(top: InlineArray[Int, MAX_N], i: Int, j: Int, k: Int) -> Int:
    let a = top[i]
    let b = top[j]
    let c = top[k]
    if a < b and b < c: return 1
    if a < c and c < b: return 2
    if b < a and a < c: return 3
    if b < c and c < a: return 4
    if c < a and a < b: return 5
    return 0

fn covered(adj: InlineArray[Bool, MAX_N * MAX_N], n: Int,
           y: Int, selected: InlineArray[Int, 5], count: Int) -> Bool:
    for z in range(count):
        if adj[selected[z] * MaxN + y]: return True
    return False

fn irredundant(adj: InlineArray[Bool, MAX_N * MAX_N], n: Int,
               selected: InlineArray[Int, 5], count: Int) -> Bool:
    for x in range(count):
        var found = False
        for y in range(n):
            if not adj[selected[x] * MaxN + y]: continue
            var shared = False
            for z in range(count):
                if z != x and adj[selected[z] * MaxN + y]:
                    shared = True
                    break
            if not shared:
                found = True
                break
        if not found: return False
    return True

fn private_min_rank(top: InlineArray[Int, MAX_N], adj: InlineArray[Bool, MAX_N * MAX_N],
                    n: Int, x: Int, selected: InlineArray[Int, 5], count: Int) -> Int:
    var best = -1
    for y in range(n):
        if not adj[x * MaxN + y]: continue
        var shared = False
        for z in range(count):
            if selected[z] != x and adj[selected[z] * MaxN + y]:
                shared = True
                break
        if not shared and (best < 0 or top[y] < top[best]): best = y
    return best

fn is_initial(top: InlineArray[Int, MAX_N], adj: InlineArray[Bool, MAX_N * MAX_N],
              n: Int, i: Int, j: Int, k: Int, r: Int, s: Int) -> Bool:
    var tri = InlineArray[Int, 5](fill=0)
    tri[0] = i; tri[1] = j; tri[2] = k
    if r != n or not irredundant(adj, n, tri, 3): return False
    let kind = graph_case(top, i, j, k)
    if kind == 1:
        for y in range(n):
            if y < i and top[y] < top[i]: return False
        return s == private_min_rank(top, adj, n, i, tri, 3)
    if kind == 2:
        if s != n: return False
        for y in range(n):
            if top[y] < top[k] and y < j and not covered(adj, n, y, tri, 3): return False
        return True
    if kind == 3:
        for y in range(n):
            if top[y] < top[j] and y < i: return False
        return s == private_min_rank(top, adj, n, j, tri, 3)
    if kind == 4:
        if s != n: return False
        for y in range(n):
            if top[y] < top[j] and y < i and not covered(adj, n, y, tri, 3): return False
        return True
    if kind == 5:
        for y in range(n):
            if top[y] < top[k] and y < i: return False
        return s == private_min_rank(top, adj, n, k, tri, 3)
    return False

fn is_regular(top: InlineArray[Int, MAX_N], adj: InlineArray[Bool, MAX_N * MAX_N],
              n: Int, i: Int, j: Int, k: Int, r: Int, s: Int) -> Bool:
    var tri = InlineArray[Int, 5](fill=0)
    tri[0] = i; tri[1] = j; tri[2] = k
    if not irredundant(adj, n, tri, 3): return False
    let kind = graph_case(top, i, j, k)
    if kind >= 1 and kind <= 4:
        if r < 0 or r >= i: return False
    elif kind == 5:
        if r != n: return False
    else:
        return False
    if kind == 2 or kind == 4: return s == n
    if s < 0 or s >= n: return False
    if kind == 1:
        return adj[i * MaxN + s] and not adj[r * MaxN + s] and not adj[j * MaxN + s] and not adj[k * MaxN + s]
    if kind == 3:
        return adj[j * MaxN + s] and not adj[r * MaxN + s] and not adj[i * MaxN + s] and not adj[k * MaxN + s]
    return adj[k * MaxN + s] and not adj[i * MaxN + s] and not adj[j * MaxN + s]

fn is_final(top: InlineArray[Int, MAX_N], adj: InlineArray[Bool, MAX_N * MAX_N],
            n: Int, i: Int, j: Int, k: Int, r: Int) -> Bool:
    var selected = InlineArray[Int, 5](fill=0)
    selected[0] = i; selected[1] = j; selected[2] = k
    var count = 3
    if r != n:
        selected[0] = r; selected[1] = i; selected[2] = j; selected[3] = k
        count = 4
    for y in range(n):
        if i < y and top[i] < top[y] and not covered(adj, n, y, selected, count): return False
    return True

fn state_index(i: Int, j: Int, k: Int, r: Int, s: Int, base: Int) -> Int:
    return ((((i * base + j) * base + k) * base + r) * base + s)

fn successor(top: InlineArray[Int, MAX_N], top_vertex: InlineArray[Int, MAX_N],
             adj: InlineArray[Bool, MAX_N * MAX_N], n: Int, i: Int, j: Int, k: Int,
             r: Int, s: Int, ell: Int, mut out_r: Int, mut out_s: Int) -> Bool:
    let kind = graph_case(top, j, k, ell)
    if kind == 0: return False
    var selected = InlineArray[Int, 5](fill=0)
    selected[0] = i; selected[1] = j; selected[2] = k; selected[3] = ell
    var count = 4
    if r != n:
        selected[0] = r; selected[1] = i; selected[2] = j; selected[3] = k; selected[4] = ell
        count = 5
    if not irredundant(adj, n, selected, count): return False
    if s != n and top[ell] <= top[s]: return False
    if not adj[j * MaxN + k]:
        for y in range(n):
            if i < y and y < j and top[i] < top[y] and top[y] < top[j] and not covered(adj, n, y, selected, count): return False
    if adj[i * MaxN + k]:
        for y in range(n):
            if j < y and y < k and top[j] < top[y] and top[y] < top[ell] and not covered(adj, n, y, selected, count): return False
    if kind == 5:
        out_r = n
    else:
        var highest = top[i]
        if r != n and top[r] > highest: highest = top[r]
        out_r = top_vertex[highest]
    if kind == 2 or kind == 4:
        out_s = n
    else:
        let old_min = min(top[i], min(top[j], top[k]))
        let next_min = min(top[j], min(top[k], top[ell]))
        if s != n and old_min == next_min:
            out_s = s
        else:
            var y = j
            if top[k] < top[y]: y = k
            if top[ell] < top[y]: y = ell
            out_s = private_min_rank(top, adj, n, y, selected, count)
            if out_s < 0: return False
    return is_regular(top, adj, n, j, k, ell, out_r, out_s)

fn dominates(mask: UInt32, hoods: InlineArray[UInt32, MAX_N], n: Int) -> Bool:
    var cover: UInt32 = 0
    for x in range(n):
        if (mask & (UInt32(1) << x)) != 0: cover = cover | hoods[x]
    return cover == ((UInt32(1) << n) - 1)

fn solve(top: InlineArray[Int, MAX_N], n: Int) -> Int64:
    var top_vertex = InlineArray[Int, MAX_N](fill=0)
    var adj = InlineArray[Bool, MAX_N * MAX_N](fill=False)
    for x in range(n):
        top_vertex[top[x]] = x
        adj[x * MaxN + x] = True
    for x in range(n):
        for y in range(x + 1, n):
            adj[x * MaxN + y] = top[x] > top[y]
            adj[y * MaxN + x] = adj[x * MaxN + y]
    let base = n + 1
    var ways = InlineArray[Int64, MAX_STATES](fill=0)
    var answer: Int64 = 0
    if n >= 3:
        for i in range(n - 3, -1, -1):
            for j in range(i + 1, n - 1):
                for k in range(j + 1, n):
                    var tri = InlineArray[Int, 5](fill=0)
                    tri[0] = i; tri[1] = j; tri[2] = k
                    if graph_case(top, i, j, k) == 0 or not irredundant(adj, n, tri, 3): continue
                    for ri in range(i + 1):
                        let r = n if ri == i else ri
                        for s in range(n + 1):
                            if not is_initial(top, adj, n, i, j, k, r, s) and not is_regular(top, adj, n, i, j, k, r, s): continue
                            var paths: Int64 = 1 if is_final(top, adj, n, i, j, k, r) else 0
                            for ell in range(k + 1, n):
                                var nr: Int = 0
                                var ns: Int = 0
                                if successor(top, top_vertex, adj, n, i, j, k, r, s, ell, mut nr, mut ns):
                                    paths += ways[state_index(j, k, ell, nr, ns, base)]
                            ways[state_index(i, j, k, r, s, base)] = paths
                            if is_initial(top, adj, n, i, j, k, r, s): answer += paths
    var hoods = InlineArray[UInt32, MAX_N](fill=0)
    for x in range(n):
        for y in range(n):
            if adj[x * MaxN + y]: hoods[x] = hoods[x] | (UInt32(1) << y)
    let full = (UInt32(1) << n) - 1
    for mask in range(1, Int(full) + 1):
        let bits = UInt32(mask)
        var size = 0
        var remaining = bits
        while remaining != 0:
            size += Int(remaining & 1)
            remaining >>= 1
        if size > 2 or not dominates(bits, hoods, n): continue
        var minimal = True
        for x in range(n):
            let bit = UInt32(1) << x
            if (bits & bit) != 0 and dominates(bits ^ bit, hoods, n): minimal = False
        if minimal: answer += 1
    return answer

@export("minimal_dominating_sets_permutation_graphs")
fn minimal_dominating_sets_permutation_graphs(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH: return -1
    let raw_n = input[0]
    if raw_n < 1 or raw_n > MAX_N: return -1
    let n = Int(raw_n)
    if length != c_size_t(n + 1): return -1
    var top = InlineArray[Int, MAX_N](fill=0)
    var seen = InlineArray[Bool, MAX_N](fill=False)
    for x in range(n):
        let raw_rank = input[x + 1]
        if raw_rank < 0 or raw_rank >= raw_n: return -1
        let rank = Int(raw_rank)
        if seen[rank]: return -1
        seen[rank] = True
        top[x] = rank
    return solve(top, n)
