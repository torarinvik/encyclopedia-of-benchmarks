from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_N = 32
comptime MAX_M = 96
comptime MAX_D = 192

struct LRInterval:
    var low: Int32
    var high: Int32

struct LRConflict:
    var left: LRInterval
    var right: LRInterval

struct LRState:
    var n: Int
    var m: Int
    var edge_of: InlineArray[Int32, 1024]
    var adj: InlineArray[Int32, 1024]
    var degree: InlineArray[Int32, 32]
    var eu: InlineArray[Int32, 96]
    var ev: InlineArray[Int32, 96]
    var tail: InlineArray[Int32, 96]
    var head: InlineArray[Int32, 96]
    var low: InlineArray[Int32, 96]
    var low2: InlineArray[Int32, 96]
    var nest: InlineArray[Int32, 96]
    var reference: InlineArray[Int32, 96]
    var side: InlineArray[Int32, 96]
    var low_edge: InlineArray[Int32, 96]
    var bottom: InlineArray[Int32, 96]
    var height: InlineArray[Int32, 32]
    var parent: InlineArray[Int32, 32]
    var out: InlineArray[Int32, 1024]
    var out_count: InlineArray[Int32, 32]
    var stack: InlineArray[LRConflict, 192]
    var stack_len: Int
    var rotation: InlineArray[Int32, 1024]
    var rotation_count: InlineArray[Int32, 32]
    var left_ref: InlineArray[Int32, 32]
    var right_ref: InlineArray[Int32, 32]
    var roots: InlineArray[Int32, 32]
    var root_count: Int

    fn __init__(inout self):
        self.n = 0
        self.m = 0
        self.edge_of = InlineArray[Int32, 1024](fill=-1)
        self.adj = InlineArray[Int32, 1024](fill=0)
        self.degree = InlineArray[Int32, 32](fill=0)
        self.eu = InlineArray[Int32, 96](fill=0)
        self.ev = InlineArray[Int32, 96](fill=0)
        self.tail = InlineArray[Int32, 96](fill=-1)
        self.head = InlineArray[Int32, 96](fill=-1)
        self.low = InlineArray[Int32, 96](fill=0)
        self.low2 = InlineArray[Int32, 96](fill=0)
        self.nest = InlineArray[Int32, 96](fill=0)
        self.reference = InlineArray[Int32, 96](fill=-1)
        self.side = InlineArray[Int32, 96](fill=1)
        self.low_edge = InlineArray[Int32, 96](fill=-1)
        self.bottom = InlineArray[Int32, 96](fill=-1)
        self.height = InlineArray[Int32, 32](fill=-1)
        self.parent = InlineArray[Int32, 32](fill=-1)
        self.out = InlineArray[Int32, 1024](fill=0)
        self.out_count = InlineArray[Int32, 32](fill=0)
        self.stack = InlineArray[LRConflict, 192]()
        self.stack_len = 0
        self.rotation = InlineArray[Int32, 1024](fill=0)
        self.rotation_count = InlineArray[Int32, 32](fill=0)
        self.left_ref = InlineArray[Int32, 32](fill=-1)
        self.right_ref = InlineArray[Int32, 32](fill=-1)
        self.roots = InlineArray[Int32, 32](fill=0)
        self.root_count = 0

fn empty_interval() -> LRInterval:
    return LRInterval(low=-1, high=-1)

fn empty_conflict() -> LRConflict:
    return LRConflict(left=empty_interval(), right=empty_interval())

fn update_parent(inout s: LRState, back: Int, pe: Int):
    if pe < 0: return
    if s.low[back] < s.low[pe]:
        s.low2[pe] = min(s.low[pe], s.low2[back])
        s.low[pe] = s.low[back]
    elif s.low[back] > s.low[pe]:
        s.low2[pe] = min(s.low2[pe], s.low[back])
    else:
        s.low2[pe] = min(s.low2[pe], s.low2[back])

fn orient(inout s: LRState, v: Int):
    let pe = Int(s.parent[v])
    for i in range(Int(s.degree[v])):
        let w = Int(s.adj[v * MAX_N + i])
        let e = Int(s.edge_of[v * MAX_N + w])
        if s.tail[e] >= 0: continue
        s.tail[e] = Int32(v)
        s.head[e] = Int32(w)
        s.low[e] = s.height[v]
        s.low2[e] = s.height[v]
        if s.height[w] < 0:
            s.parent[w] = Int32(e)
            s.height[w] = s.height[v] + 1
            orient(s, w)
            s.nest[e] = 2 * s.low[e] + (1 if s.low2[e] < s.height[v] else 0)
        else:
            s.low[e] = s.height[w]
            s.low2[e] = s.height[v]
            s.nest[e] = 2 * s.low[e] + (1 if s.low2[e] < s.height[v] else 0)
        update_parent(s, e, pe)

fn conflicts(s: LRState, a: LRInterval, e: Int) -> Bool:
    return a.high >= 0 and s.low[Int(a.high)] > s.low[e]

fn pair_lowest(s: LRState, p: LRConflict) -> Int32:
    let a = s.low[Int(p.left.low)] if p.left.low >= 0 else Int32(1000)
    let b = s.low[Int(p.right.low)] if p.right.low >= 0 else Int32(1000)
    return min(a, b)

fn add_constraints(inout s: LRState, ei: Int, pe: Int) -> Bool:
    var p = empty_conflict()
    while True:
        if s.stack_len == 0: return False
        s.stack_len -= 1
        var q = s.stack[s.stack_len]
        if q.left.low >= 0:
            let t = q.left
            q.left = q.right
            q.right = t
        if q.left.low >= 0: return False
        if s.low[Int(q.right.low)] > s.low[pe]:
            if p.right.low < 0: p.right = q.right
            else:
                s.reference[Int(p.right.low)] = q.right.high
                p.right.low = q.right.low
        else:
            s.reference[Int(q.right.low)] = s.low_edge[pe]
        if Int(s.stack_len) - 1 == Int(s.bottom[ei]): break
    while s.stack_len > 0 and (conflicts(s, s.stack[s.stack_len - 1].left, ei) or conflicts(s, s.stack[s.stack_len - 1].right, ei)):
        s.stack_len -= 1
        var q = s.stack[s.stack_len]
        if conflicts(s, q.right, ei):
            let t = q.left
            q.left = q.right
            q.right = t
        if conflicts(s, q.right, ei): return False
        if p.right.low >= 0: s.reference[Int(p.right.low)] = q.right.high
        if q.right.low >= 0: p.right.low = q.right.low
        if p.left.low < 0: p.left = q.left
        else:
            s.reference[Int(p.left.low)] = q.left.high
            p.left.low = q.left.low
    if p.left.low >= 0 or p.right.low >= 0:
        s.stack[s.stack_len] = p
        s.stack_len += 1
    return True

fn remove_returns(inout s: LRState, e: Int):
    let u = Int(s.tail[e])
    while s.stack_len > 0 and pair_lowest(s, s.stack[s.stack_len - 1]) == s.height[u]:
        s.stack_len -= 1
        let p = s.stack[s.stack_len]
        if p.left.low >= 0: s.side[Int(p.left.low)] = -1
    if s.stack_len > 0:
        s.stack_len -= 1
        var p = s.stack[s.stack_len]
        while p.left.high >= 0 and s.head[Int(p.left.high)] == u: p.left.high = s.reference[Int(p.left.high)]
        if p.left.high < 0 and p.left.low >= 0:
            s.reference[Int(p.left.low)] = p.right.low
            s.side[Int(p.left.low)] = -1
            p.left.low = -1
        while p.right.high >= 0 and s.head[Int(p.right.high)] == u: p.right.high = s.reference[Int(p.right.high)]
        if p.right.high < 0 and p.right.low >= 0:
            s.reference[Int(p.right.low)] = p.left.low
            s.side[Int(p.right.low)] = -1
            p.right.low = -1
        s.stack[s.stack_len] = p
        s.stack_len += 1
    if s.low[e] < s.height[u] and s.stack_len > 0:
        let p = s.stack[s.stack_len - 1]
        let lh = p.left.high
        let rh = p.right.high
        s.reference[e] = lh if lh >= 0 and (rh < 0 or s.low[Int(lh)] > s.low[Int(rh)]) else rh

fn test_dfs(inout s: LRState, v: Int) -> Bool:
    let pe = Int(s.parent[v])
    for i in range(Int(s.out_count[v])):
        let e = Int(s.out[v * MAX_N + i])
        let w = Int(s.head[e])
        s.bottom[e] = Int32(s.stack_len - 1)
        if s.parent[w] == e:
            if not test_dfs(s, w): return False
        else:
            s.low_edge[e] = Int32(e)
            var p = empty_conflict()
            p.right = LRInterval(low=Int32(e), high=Int32(e))
            s.stack[s.stack_len] = p
            s.stack_len += 1
            if s.low[e] < s.height[v]:
                if i == 0:
                    if pe >= 0: s.low_edge[pe] = Int32(e)
                elif pe < 0 or not add_constraints(s, e, pe):
                    return False
    if pe >= 0: remove_returns(s, pe)
    return True

fn resolve_side(inout s: LRState, e: Int) -> Int32:
    if s.reference[e] >= 0:
        let r = Int(s.reference[e])
        s.side[e] *= resolve_side(s, r)
        s.reference[e] = -1
    return s.side[e]

fn edge_before(s: LRState, a: Int, b: Int, depth: InlineArray[Int32, 96]) -> Bool:
    return depth[a] < depth[b] or (depth[a] == depth[b] and s.head[a] < s.head[b])

fn insert_neighbor(inout s: LRState, v: Int, w: Int, reference: Int, after: Bool):
    let count = Int(s.rotation_count[v])
    var pos = 0
    if count > 0 and reference >= 0:
        while pos < count and s.rotation[v * MAX_N + pos] != reference: pos += 1
        if pos == count: pos = count
        elif after: pos = (pos + 1) % count
    for i in range(count, pos, -1): s.rotation[v * MAX_N + i] = s.rotation[v * MAX_N + i - 1]
    s.rotation[v * MAX_N + pos] = Int32(w)
    s.rotation_count[v] = Int32(count + 1)

fn embed(inout s: LRState, v: Int):
    for i in range(Int(s.out_count[v])):
        let e = Int(s.out[v * MAX_N + i])
        let w = Int(s.head[e])
        if s.parent[w] == e:
            insert_neighbor(s, w, v, -1, False)
            s.left_ref[v] = Int32(w)
            s.right_ref[v] = Int32(w)
            embed(s, w)
        elif s.side[e] == 1:
            insert_neighbor(s, w, v, Int(s.right_ref[w]), True)
        else:
            insert_neighbor(s, w, v, Int(s.left_ref[w]), False)
            s.left_ref[w] = Int32(v)

@export("planar_embedding_lr")
fn planar_embedding_lr(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(2) or length > c_size_t(195): return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 1 or n64 > MAX_N or m64 < 0 or m64 > MAX_M or length != c_size_t(2 + 2 * m64): return -1
    var s = LRState()
    s.n = Int(n64)
    s.m = Int(m64)
    for v in range(s.n):
        s.height[v] = -1
        s.parent[v] = -1
        s.left_ref[v] = -1
        s.right_ref[v] = -1
        for w in range(s.n): s.edge_of[v * MAX_N + w] = -1
    for e in range(s.m):
        let u64 = input[2 + 2 * e]
        let v64 = input[3 + 2 * e]
        if u64 < 0 or u64 >= v64 or v64 >= n64: return -1
        let u = Int(u64)
        let v = Int(v64)
        if s.edge_of[u * MAX_N + v] >= 0: return -1
        s.edge_of[u * MAX_N + v] = Int32(e)
        s.edge_of[v * MAX_N + u] = Int32(e)
        s.eu[e] = Int32(u)
        s.ev[e] = Int32(v)
    for v in range(s.n):
        for w in range(s.n):
            if s.edge_of[v * MAX_N + w] >= 0:
                s.adj[v * MAX_N + Int(s.degree[v])] = Int32(w)
                s.degree[v] += 1
    for root in range(s.n):
        if s.height[root] < 0:
            s.height[root] = 0
            s.roots[s.root_count] = Int32(root)
            s.root_count += 1
            orient(s, root)
    for e in range(s.m):
        let v = Int(s.tail[e])
        s.out[v * MAX_N + Int(s.out_count[v])] = Int32(e)
        s.out_count[v] += 1
    for v in range(s.n):
        for i in range(1, Int(s.out_count[v])):
            let e = Int(s.out[v * MAX_N + i])
            var j = i
            while j > 0 and edge_before(s, e, Int(s.out[v * MAX_N + j - 1]), s.nest):
                s.out[v * MAX_N + j] = s.out[v * MAX_N + j - 1]
                j -= 1
            s.out[v * MAX_N + j] = Int32(e)
    var planar = True
    for i in range(s.root_count):
        if not test_dfs(s, Int(s.roots[i])):
            planar = False
            break
    if output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    if not planar:
        if capacity < c_size_t(1): return -2
        output[0] = 0
        return 1
    var depth = InlineArray[Int32, 96](fill=0)
    for e in range(s.m): depth[e] = s.nest[e] * resolve_side(s, e)
    for v in range(s.n):
        for i in range(1, Int(s.out_count[v])):
            let e = Int(s.out[v * MAX_N + i])
            var j = i
            while j > 0 and edge_before(s, e, Int(s.out[v * MAX_N + j - 1]), depth):
                s.out[v * MAX_N + j] = s.out[v * MAX_N + j - 1]
                j -= 1
            s.out[v * MAX_N + j] = Int32(e)
    for v in range(s.n):
        for i in range(Int(s.out_count[v])):
            s.rotation[v * MAX_N + Int(s.rotation_count[v])] = s.head[Int(s.out[v * MAX_N + i])]
            s.rotation_count[v] += 1
    for i in range(s.root_count): embed(s, Int(s.roots[i]))
    let needed = 1 + 2 * s.m
    if capacity < c_size_t(needed): return -2
    output[0] = 1
    var at = 1
    for v in range(s.n):
        for i in range(Int(s.rotation_count[v])):
            output[at] = UInt8(s.rotation[v * MAX_N + i])
            at += 1
    return Int64(needed)
