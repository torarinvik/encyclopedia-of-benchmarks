from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias KPY_N = 16
alias KPY_M = 42
alias KPY_K = 14
alias KPY_D = 84
alias KPY_VALID = 312
alias KPY_PARSEABLE = 313

@export("kanj_perkovic_modified_yao_spanner")
fn kanj_perkovic_modified_yao_spanner(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > KPY_PARSEABLE:
        return -1
    let n64 = input[0]
    let m64 = input[1]
    if n64 < 3 or n64 > KPY_N or m64 < n64 - 1 or m64 > KPY_M or m64 > 3 * n64 - 6:
        return -1
    let n = Int(n64)
    let m = Int(m64)
    let dart_count = 2 * m
    if length != c_size_t(2 + n + 7 * m) or length > KPY_VALID: return -1

    var edge_u = InlineArray[Int, KPY_M]()
    var edge_v = InlineArray[Int, KPY_M]()
    var cone_u = InlineArray[Int, KPY_M]()
    var cone_v = InlineArray[Int, KPY_M]()
    var weight = InlineArray[Int64, KPY_M]()
    var adjacent = InlineArray[Bool, KPY_N * KPY_N]()
    var expected_degree = InlineArray[Int, KPY_N]()
    var source = InlineArray[Int, KPY_D]()
    var cone = InlineArray[Int, KPY_D]()
    for edge in range(m):
        let p = 2 + 5 * edge
        let u64 = input[p]
        let v64 = input[p + 1]
        let w = input[p + 2]
        let cu64 = input[p + 3]
        let cv64 = input[p + 4]
        if u64 < 0 or u64 >= v64 or v64 >= n64 or w < 1 or w > 1_000_000_000_000 or
            cu64 < 0 or cu64 >= KPY_K or cv64 < 0 or cv64 >= KPY_K: return -1
        let u = Int(u64)
        let v = Int(v64)
        if edge > 0 and (u < edge_u[edge - 1] or (u == edge_u[edge - 1] and v <= edge_v[edge - 1])): return -1
        let cu = Int(cu64)
        let cv = Int(cv64)
        edge_u[edge] = u; edge_v[edge] = v; weight[edge] = w
        cone_u[edge] = cu; cone_v[edge] = cv
        adjacent[u * KPY_N + v] = True; adjacent[v * KPY_N + u] = True
        expected_degree[u] += 1; expected_degree[v] += 1
        source[2 * edge] = u; source[2 * edge + 1] = v
        cone[2 * edge] = cu; cone[2 * edge + 1] = cv

    var rotation = InlineArray[Int, KPY_D]()
    var position = InlineArray[Int, KPY_D]()
    var row_start = InlineArray[Int, KPY_N]()
    var degree = InlineArray[Int, KPY_N]()
    var first = InlineArray[Int, KPY_N * KPY_K]()
    var after = InlineArray[Int, KPY_N * KPY_K]()
    var seen = InlineArray[Bool, KPY_D]()
    for i in range(KPY_N * KPY_K): first[i] = -1; after[i] = -1
    var cursor = 2 + 5 * m
    var used = 0
    for vertex in range(n):
        let d64 = input[cursor]
        cursor += 1
        if d64 < 1 or d64 > KPY_D or Int(d64) != expected_degree[vertex]: return -1
        let d = Int(d64)
        row_start[vertex] = used; degree[vertex] = d
        var previous = -1
        for _ in range(d):
            let raw = input[cursor]
            cursor += 1
            if raw < 0 or raw >= Int64(dart_count): return -1
            let dart = Int(raw)
            let c = cone[dart]
            if seen[dart] or source[dart] != vertex or c < previous: return -1
            previous = c; seen[dart] = True
            rotation[used] = dart; position[dart] = used
            let bucket = vertex * KPY_K + c
            if first[bucket] < 0: first[bucket] = used
            after[bucket] = used + 1
            used += 1
    if cursor != Int(length) or used != dart_count: return -1
    for dart in range(dart_count):
        if not seen[dart]: return -1

    var reached = InlineArray[Bool, KPY_N]()
    var queue = InlineArray[Int, KPY_N]()
    var head = 0
    var tail = 1
    queue[0] = 0; reached[0] = True
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if adjacent[u * KPY_N + v] and not reached[v]:
                reached[v] = True; queue[tail] = v; tail += 1
    if tail != n: return -1

    var next_face = InlineArray[Int, KPY_D]()
    var face_seen = InlineArray[Bool, KPY_D]()
    var faces = 0
    for dart in range(dart_count):
        let twin = dart ^ 1
        let dest = source[twin]
        let local = position[twin] - row_start[dest]
        next_face[dart] = rotation[row_start[dest] + (local + degree[dest] - 1) % degree[dest]]
    for dart in range(dart_count):
        if not face_seen[dart]:
            faces += 1
            var current = dart
            while not face_seen[current]:
                face_seen[current] = True
                current = next_face[current]
            if current != dart: return -1
    if n - m + faces != 2: return -1

    var selected = InlineArray[Bool, KPY_D]()
    for vertex in range(n):
        for c in range(KPY_K):
            let bucket = vertex * KPY_K + c
            if first[bucket] < 0: continue
            var best = -1
            for p in range(first[bucket], after[bucket]):
                let dart = rotation[p]
                let edge = dart / 2
                if best < 0 or weight[edge] < weight[best / 2] or
                    (weight[edge] == weight[best / 2] and edge < best / 2): best = dart
            selected[best] = True
    for vertex in range(n):
        var occupied = False
        for c in range(KPY_K):
            if first[vertex * KPY_K + c] >= 0: occupied = True
        if not occupied: continue
        for start in range(KPY_K):
            if first[vertex * KPY_K + start] >= 0 or first[vertex * KPY_K + (start + KPY_K - 1) % KPY_K] < 0: continue
            var run = 0
            while run < KPY_K and first[vertex * KPY_K + (start + run) % KPY_K] < 0: run += 1
            if run == 1:
                let cw_cone = (start + KPY_K - 1) % KPY_K
                let ccw_cone = (start + 1) % KPY_K
                let cw = rotation[after[vertex * KPY_K + cw_cone] - 1]
                let ccw = rotation[first[vertex * KPY_K + ccw_cone]]
                if selected[cw]: selected[ccw] = True
                elif selected[ccw]: selected[cw] = True
                else:
                    let a = cw / 2; let b = ccw / 2
                    selected[if weight[a] < weight[b] or (weight[a] == weight[b] and a < b): cw else: ccw] = True
            else:
                var cw_left = run / 2
                var ccw_left = (run + 1) / 2
                for step in range(1, KPY_K + 1):
                    if cw_left == 0: break
                    let c = (start + KPY_K - step) % KPY_K
                    let bucket = vertex * KPY_K + c
                    if first[bucket] >= 0:
                        for p in range(after[bucket] - 1, first[bucket] - 1, -1):
                            if cw_left == 0: break
                            let dart = rotation[p]
                            if not selected[dart]: selected[dart] = True; cw_left -= 1
                for step in range(run, run + KPY_K):
                    if ccw_left == 0: break
                    let c = (start + step) % KPY_K
                    let bucket = vertex * KPY_K + c
                    if first[bucket] >= 0:
                        for p in range(first[bucket], after[bucket]):
                            if ccw_left == 0: break
                            let dart = rotation[p]
                            if not selected[dart]: selected[dart] = True; ccw_left -= 1
    var mask: UInt64 = 0
    for edge in range(m):
        if selected[2 * edge] and selected[2 * edge + 1]: mask |= UInt64(1) << edge
    return Int64(mask)
