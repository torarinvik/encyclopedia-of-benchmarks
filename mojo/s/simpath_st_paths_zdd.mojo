from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_M = 9
comptime MAX_STATES = 1023
comptime MAX_ZDD = 511
comptime MAX_INPUT = 23
comptime RADIX = 2048

struct Memo(Copyable):
    var level: Int
    var mate: InlineArray[UInt8, MAX_N]
    var result: Int

struct ZNode(Copyable):
    var level: Int
    var low: Int
    var high: Int

struct Transition(Copyable):
    var status: Int
    var mate: InlineArray[UInt8, MAX_N]

fn degree_of(mate: InlineArray[UInt8, MAX_N], vertex: Int) -> Int:
    if Int(mate[vertex]) == vertex + 1: return 0
    if mate[vertex] == 0: return 2
    return 1

// Status 0 prunes, 1 supplies a suffix state, and 2 is the one-terminal.
fn transition(
    n: Int, source: Int, target: Int, level: Int,
    edges: InlineArray[Int, 2 * MAX_M], last: InlineArray[Int, MAX_N],
    mate: InlineArray[UInt8, MAX_N], selected: Bool
) -> Transition:
    var next = mate
    if selected:
        let u = edges[2 * level]
        let v = edges[2 * level + 1]
        let du = degree_of(next, u)
        let dv = degree_of(next, v)
        if du == 2 or dv == 2: return Transition(0, next)
        if (u == source or u == target) and du == 1: return Transition(0, next)
        if (v == source or v == target) and dv == 1: return Transition(0, next)
        let mu = Int(next[u])
        let mv = Int(next[v])
        if mu == v + 1 and mv == u + 1: return Transition(0, next)
        if (mu == source + 1 and mv == target + 1) or (mu == target + 1 and mv == source + 1):
            for w in range(n):
                if w != source and w != target and w != u and w != v and degree_of(next, w) == 1:
                    return Transition(0, next)
            return Transition(2, next)
        next[u] = 0
        next[v] = 0
        next[mu - 1] = UInt8(mv)
        next[mv - 1] = UInt8(mu)
    for w in range(n):
        if last[w] != level: continue
        let degree = degree_of(next, w)
        if w == source or w == target:
            if degree == 0: return Transition(0, next)
        else:
            if degree == 1: return Transition(0, next)
            next[w] = UInt8(w + 1)
    return Transition(1, next)

fn solve(
    n: Int, m: Int, source: Int, target: Int, level: Int,
    edges: InlineArray[Int, 2 * MAX_M], last: InlineArray[Int, MAX_N],
    mate: InlineArray[UInt8, MAX_N],
    mut memo: InlineArray[Memo, MAX_STATES], mut memo_count: Int,
    mut nodes: InlineArray[ZNode, MAX_ZDD], mut node_count: Int
) -> Int:
    if level == m: return 0
    for i in range(memo_count):
        let entry = memo[i]
        if entry.level != level: continue
        var equal = True
        for v in range(n):
            if entry.mate[v] != mate[v]:
                equal = False
                break
        if equal: return entry.result

    let low_transition = transition(n, source, target, level, edges, last, mate, False)
    var low = 0
    if low_transition.status != 0:
        low = solve(n, m, source, target, level + 1, edges, last, low_transition.mate,
                    mut memo, mut memo_count, mut nodes, mut node_count)
    let high_transition = transition(n, source, target, level, edges, last, mate, True)
    var high = 0
    if high_transition.status == 2:
        high = 1
    elif high_transition.status == 1:
        high = solve(n, m, source, target, level + 1, edges, last, high_transition.mate,
                     mut memo, mut memo_count, mut nodes, mut node_count)
    var result = low
    if high != 0:
        var found = False
        for i in range(node_count):
            let node = nodes[i]
            if node.level == level and node.low == low and node.high == high:
                result = i + 2
                found = True
                break
        if not found:
            if node_count >= MAX_ZDD: return -1
            nodes[node_count] = ZNode(level, low, high)
            node_count += 1
            result = node_count + 1
    if memo_count >= MAX_STATES: return -1
    memo[memo_count] = Memo(level, mate, result)
    memo_count += 1
    return result

fn reachable_count(nodes: InlineArray[ZNode, MAX_ZDD], node_count: Int, root: Int) -> Int:
    var seen = InlineArray[Bool, MAX_ZDD + 2](fill=False)
    var stack = InlineArray[Int, 2 * MAX_ZDD + 3](fill=0)
    var top = 1
    var count = 0
    stack[0] = root
    while top > 0:
        top -= 1
        let id = stack[top]
        if id <= 1 or seen[id]: continue
        seen[id] = True
        count += 1
        let node = nodes[id - 2]
        stack[top] = node.low
        top += 1
        stack[top] = node.high
        top += 1
    return count

@export("simpath_st_paths_zdd")
fn simpath_st_paths_zdd(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_INPUT: return -1
    let n64 = input[0]
    let m64 = input[1]
    let s64 = input[2]
    let t64 = input[3]
    if n64 < 2 or n64 > MAX_N or m64 < 0 or m64 > MAX_M or s64 < 0 or s64 >= n64 or t64 < 0 or t64 >= n64 or s64 == t64:
        return -1
    let n = Int(n64)
    let m = Int(m64)
    let source = Int(s64)
    let target = Int(t64)
    if length != c_size_t(4 + 2 * m): return -1
    var edges = InlineArray[Int, 2 * MAX_M](fill=0)
    var last = InlineArray[Int, MAX_N](fill=-1)
    for i in range(m):
        let u64 = input[4 + 2 * i]
        let v64 = input[5 + 2 * i]
        if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
        let u = Int(u64)
        let v = Int(v64)
        for j in range(i):
            if edges[2 * j] == u and edges[2 * j + 1] == v: return -1
        edges[2 * i] = u
        edges[2 * i + 1] = v
        last[u] = i
        last[v] = i
    var initial = InlineArray[UInt8, MAX_N](fill=0)
    for v in range(n): initial[v] = UInt8(v + 1)
    var memo = InlineArray[Memo, MAX_STATES](fill=Memo(0, InlineArray[UInt8, MAX_N](fill=0), 0))
    var nodes = InlineArray[ZNode, MAX_ZDD](fill=ZNode(0, 0, 0))
    var memo_count = 0
    var node_count = 0
    let root = solve(n, m, source, target, 0, edges, last, initial,
                     mut memo, mut memo_count, mut nodes, mut node_count)
    if root < 0: return -1
    var ways = InlineArray[UInt16, MAX_ZDD + 2](fill=0)
    ways[1] = 1
    for id in range(2, node_count + 2):
        let node = nodes[id - 2]
        ways[id] = ways[node.low] + ways[node.high]
    let path_count = Int(ways[root])
    if path_count >= 2048: return -1
    return Int64(reachable_count(nodes, node_count, root) * 2048 + path_count)
