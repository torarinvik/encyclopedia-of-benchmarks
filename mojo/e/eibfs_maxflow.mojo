from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime NMAX = 8
comptime MMAX = 24
comptime INPUT_MAX = 77
comptime FREE_TREE = 0
comptime S_TREE = 1
comptime T_TREE = 2

struct EibfsState:
    var n: Int
    var source: Int
    var sink: Int
    var forward: Bool
    var kind: InlineArray[Int, 8]
    var parent: InlineArray[Int, 8]
    var original: InlineArray[Int64, 64]
    var residual: InlineArray[Int64, 64]
    var balance: InlineArray[Int64, 8]
    var ds: InlineArray[Int64, 8]
    var dt: InlineArray[Int64, 8]
    var ds_max: Int64
    var dt_max: Int64
    var orphaned: InlineArray[Bool, 8]
    var events: Int

    fn __init__(out self):
        self.n = 0
        self.source = 0
        self.sink = 0
        self.forward = True
        self.kind = InlineArray[Int, 8](fill=FREE_TREE)
        self.parent = InlineArray[Int, 8](fill=-1)
        self.original = InlineArray[Int64, 64](fill=0)
        self.residual = InlineArray[Int64, 64](fill=0)
        self.balance = InlineArray[Int64, 8](fill=0)
        self.ds = InlineArray[Int64, 8](fill=0)
        self.dt = InlineArray[Int64, 8](fill=0)
        self.ds_max = 0
        self.dt_max = 0
        self.orphaned = InlineArray[Bool, 8](fill=False)
        self.events = 0

fn eibfs_root(state: EibfsState, start: Int) -> Int:
    var v = start
    for _ in range(state.n):
        if state.parent[v] < 0: return v
        v = state.parent[v]
    return -1

fn eibfs_bottleneck(state: EibfsState, start: Int, kind: Int) -> Int64:
    var v = start
    var answer: Int64 = 2401
    for _ in range(state.n):
        let p = state.parent[v]
        if p < 0: return answer
        let cap = state.residual[p * 8 + v] if kind == S_TREE else state.residual[v * 8 + p]
        if cap < answer: answer = cap
        v = p
    return 0

fn eibfs_push(inout state: EibfsState, u: Int, v: Int, amount: Int64):
    state.residual[u * 8 + v] -= amount
    state.residual[v * 8 + u] += amount
    if u != state.source and u != state.sink: state.balance[u] -= amount
    if v != state.source and v != state.sink: state.balance[v] += amount

fn eibfs_mark(inout state: EibfsState, v: Int, inout queue: InlineArray[Int, 512], inout tail: Int):
    if not state.orphaned[v]:
        state.orphaned[v] = True
        queue[tail] = v
        tail += 1

fn eibfs_detach(inout state: EibfsState, v: Int, kind: Int, inout queue: InlineArray[Int, 512], inout tail: Int):
    for child in range(state.n):
        if state.kind[child] == kind and state.parent[child] == v:
            state.parent[child] = -1
            eibfs_mark(inout state, child, inout queue, inout tail)

fn eibfs_adopt(inout state: EibfsState, v: Int, kind: Int, inout queue: InlineArray[Int, 512], inout tail: Int):
    let sink_side = kind == T_TREE
    state.orphaned[v] = False
    let old = state.dt[v] if sink_side else state.ds[v]
    for u in range(state.n):
        let cap = state.residual[v * 8 + u] if sink_side else state.residual[u * 8 + v]
        let here = state.dt[v] if sink_side else state.ds[v]
        let label = state.dt[u] if sink_side else state.ds[u]
        if u != v and state.kind[u] == kind and cap > 0 and here == label + 1:
            state.parent[v] = u
            return
    let frontier = state.dt_max if sink_side else state.ds_max
    let subtract = state.forward if sink_side else not state.forward
    let limit = frontier - (1 if subtract else 0)
    var best: Int64 = Int64(4 * state.n)
    for u in range(state.n):
        let cap = state.residual[v * 8 + u] if sink_side else state.residual[u * 8 + v]
        let label = state.dt[u] if sink_side else state.ds[u]
        if u != v and state.kind[u] == kind and cap > 0 and label <= limit and label < best:
            best = label
    var parent = -1
    for u in range(state.n):
        let cap = state.residual[v * 8 + u] if sink_side else state.residual[u * 8 + v]
        let label = state.dt[u] if sink_side else state.ds[u]
        if u != v and state.kind[u] == kind and cap > 0 and label == best:
            parent = u
            break
    if parent >= 0 and best + 1 > old:
        eibfs_detach(inout state, v, kind, inout queue, inout tail)
        state.parent[v] = parent
        if sink_side: state.dt[v] = best + 1
        else: state.ds[v] = best + 1
        return
    eibfs_detach(inout state, v, kind, inout queue, inout tail)
    state.parent[v] = -1
    state.kind[v] = FREE_TREE
    if sink_side and state.balance[v] > 0:
        state.kind[v] = S_TREE
        state.ds[v] = state.ds_max + (1 if state.forward else 0)
    elif not sink_side and state.balance[v] < 0:
        state.kind[v] = T_TREE
        state.dt[v] = state.dt_max + (0 if state.forward else 1)

fn eibfs_repair_orphans(inout state: EibfsState, kind: Int, inout queue: InlineArray[Int, 512], head: Int, inout tail: Int):
    var at = head
    while at < tail:
        let v = queue[at]
        at += 1
        state.orphaned[v] = False
        if state.kind[v] == kind: eibfs_adopt(inout state, v, kind, inout queue, inout tail)

fn eibfs_drain(inout state: EibfsState, start: Int, kind: Int):
    let root_vertex = eibfs_root(state, start)
    if root_vertex < 0: return
    var queue = InlineArray[Int, 512](fill=0)
    var head = 0
    var tail = 0
    var x = start
    while (kind == T_TREE and state.balance[x] > 0 or kind == S_TREE and state.balance[x] < 0) and state.parent[x] >= 0:
        let p = state.parent[x]
        let cap = state.residual[x * 8 + p] if kind == T_TREE else state.residual[p * 8 + x]
        let need = state.balance[x] if kind == T_TREE else -state.balance[x]
        let amount = need if need < cap else cap
        if amount > 0:
            if kind == T_TREE: eibfs_push(inout state, x, p, amount)
            else: eibfs_push(inout state, p, x, amount)
        let after = state.balance[x] if kind == T_TREE else -state.balance[x]
        let remaining = state.residual[x * 8 + p] if kind == T_TREE else state.residual[p * 8 + x]
        if remaining == 0 and after >= 0:
            state.parent[x] = -1
            eibfs_mark(inout state, x, inout queue, inout tail)
            break
        if after == 0: break
        x = p
    if kind == T_TREE and root_vertex != state.sink and state.kind[root_vertex] == kind and state.balance[root_vertex] >= 0:
        state.parent[root_vertex] = -1
        eibfs_mark(inout state, root_vertex, inout queue, inout tail)
    if kind == S_TREE and root_vertex != state.source and state.kind[root_vertex] == kind and state.balance[root_vertex] <= 0:
        state.parent[root_vertex] = -1
        eibfs_mark(inout state, root_vertex, inout queue, inout tail)
    eibfs_repair_orphans(inout state, kind, inout queue, head, inout tail)

fn eibfs_repair(inout state: EibfsState):
    while True:
        var found = False
        for v in range(state.n):
            if state.kind[v] == T_TREE and state.balance[v] > 0:
                eibfs_drain(inout state, v, T_TREE)
                found = True
                break
        if found: continue
        for v in range(state.n):
            if state.kind[v] == S_TREE and state.balance[v] < 0:
                eibfs_drain(inout state, v, S_TREE)
                found = True
                break
        if not found: return

fn eibfs_augment(inout state: EibfsState, v: Int, w: Int) -> Bool:
    let rs = eibfs_root(state, v)
    let rt = eibfs_root(state, w)
    if rs < 0 or rt < 0 or state.residual[v * 8 + w] <= 0: return False
    let connector = state.residual[v * 8 + w]
    let bs = eibfs_bottleneck(state, v, S_TREE)
    let bt = eibfs_bottleneck(state, w, T_TREE)
    var amount = connector
    if rs == state.source and rt == state.sink: pass
    elif rs == state.source: amount = bs if bs < connector else connector
    elif rt == state.sink: amount = connector if connector < bt else bt
    else:
        amount = state.balance[rs]
        if bs < amount: amount = bs
        if connector < amount: amount = connector
        if bt < amount: amount = bt
        if -state.balance[rt] < amount: amount = -state.balance[rt]
    if amount <= 0: return False
    eibfs_push(inout state, v, w, amount)
    eibfs_repair(inout state)
    return True

fn eibfs_solve(inout state: EibfsState) -> Int64:
    var finished = False
    for _ in range(4 * state.n + 4):
        if finished: break
        while True:
            var restart = False
            if state.forward:
                for v in range(state.n):
                    if restart: break
                    if state.kind[v] != S_TREE or state.ds[v] != state.ds_max: continue
                    for w in range(state.n):
                        if state.residual[v * 8 + w] <= 0 or state.kind[w] == S_TREE: continue
                        if state.kind[w] == FREE_TREE:
                            state.kind[w] = S_TREE
                            state.parent[w] = v
                            state.ds[w] = state.ds_max + 1
                        elif state.kind[w] == T_TREE and eibfs_augment(inout state, v, w):
                            state.events += 1
                            if state.events > 100000: return -1
                            restart = True
                            break
                if not restart:
                    var next_level = False
                    for v in range(state.n):
                        if state.kind[v] == S_TREE and state.ds[v] == state.ds_max + 1: next_level = True
                    if next_level: state.ds_max += 1
                    else: finished = True
                    break
            else:
                for w in range(state.n):
                    if restart: break
                    if state.kind[w] != T_TREE or state.dt[w] != state.dt_max: continue
                    for v in range(state.n):
                        if state.residual[v * 8 + w] <= 0 or state.kind[v] == T_TREE: continue
                        if state.kind[v] == FREE_TREE:
                            state.kind[v] = T_TREE
                            state.parent[v] = w
                            state.dt[v] = state.dt_max + 1
                        elif state.kind[v] == S_TREE and eibfs_augment(inout state, v, w):
                            state.events += 1
                            if state.events > 100000: return -1
                            restart = True
                            break
                if not restart:
                    var next_level = False
                    for v in range(state.n):
                        if state.kind[v] == T_TREE and state.dt[v] == state.dt_max + 1: next_level = True
                    if next_level: state.dt_max += 1
                    else: finished = True
                    break
            if not restart: break
        if not finished: state.forward = not state.forward
    var reachable = InlineArray[Bool, 8](fill=False)
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 0
    for v in range(state.n):
        if state.kind[v] == S_TREE:
            reachable[v] = True
            queue[tail] = v
            tail += 1
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(state.n):
            if state.residual[u * 8 + v] > 0 and not reachable[v]:
                reachable[v] = True
                queue[tail] = v
                tail += 1
    var cut: Int64 = 0
    for u in range(state.n):
        if reachable[u]:
            for v in range(state.n):
                if not reachable[v]: cut += state.original[u * 8 + v]
    return cut

@export("eibfs_maxflow")
fn eibfs_maxflow(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(4) or length > c_size_t(INPUT_MAX): return -1
    let nv = input[0]
    let mv = input[1]
    let sv = input[2]
    let tv = input[3]
    if nv < 2 or nv > NMAX or mv < 0 or mv > MMAX or sv < 0 or sv >= nv or tv < 0 or tv >= nv or sv == tv: return -1
    let n = Int(nv)
    let m = Int(mv)
    let source = Int(sv)
    let sink = Int(tv)
    if length != c_size_t(4 + 3 * m): return -1
    var state = EibfsState()
    state.n = n
    state.source = source
    state.sink = sink
    for e in range(m):
        let u = input[4 + 3 * e]
        let v = input[5 + 3 * e]
        let capacity = input[6 + 3 * e]
        if u < 0 or u >= nv or v < 0 or v >= nv or u == v or capacity < 0 or capacity > 100: return -1
        state.original[Int(u) * 8 + Int(v)] += capacity
        state.residual[Int(u) * 8 + Int(v)] += capacity
    state.kind[source] = S_TREE
    state.kind[sink] = T_TREE
    return eibfs_solve(inout state)
