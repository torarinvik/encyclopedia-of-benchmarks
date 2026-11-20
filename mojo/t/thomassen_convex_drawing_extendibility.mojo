from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const N = 8
const M = 18
const F = 12
const INPUT_MAX = 93
const FLOW_NODES = 18

fn th_connected(adjacency: InlineArray[Bool, 64], n: Int, removed: Int) -> Bool:
    let start = 1 if removed == 0 else 0
    var seen = InlineArray[Bool, 8](fill=False)
    var stack = InlineArray[Int, 8](fill=0)
    var top = 1
    var count = 0
    seen[start] = True
    stack[0] = start
    while top > 0:
        top -= 1
        let u = stack[top]
        count += 1
        for v in range(n):
            if v != removed and adjacency[u * 8 + v] and not seen[v]:
                seen[v] = True
                stack[top] = v
                top += 1
    return count == n - (1 if removed >= 0 else 0)

fn th_three_outer_paths(adjacency: InlineArray[Bool, 64], outer: InlineArray[Bool, 8],
                        n: Int, root: Int) -> Bool:
    var residual = InlineArray[Int, 324](fill=0)
    let source = 2 * n
    let sink = source + 1
    let nodes = sink + 1
    for v in range(n):
        if v != root: residual[(2 * v) * 18 + 2 * v + 1] = 1
    for u in range(n):
        for v in range(u + 1, n):
            if not adjacency[u * 8 + v]: continue
            if u == root: residual[source * 18 + 2 * v] += 1
            elif v == root: residual[source * 18 + 2 * u] += 1
            else:
                residual[(2 * u + 1) * 18 + 2 * v] += 1
                residual[(2 * v + 1) * 18 + 2 * u] += 1
    for v in range(n):
        if outer[v] and v != root: residual[(2 * v + 1) * 18 + sink] += 1
    for _ in range(3):
        var parent = InlineArray[Int, 18](fill=-1)
        var queue = InlineArray[Int, 18](fill=0)
        parent[source] = source
        queue[0] = source
        var head = 0
        var tail = 1
        while head < tail and parent[sink] < 0:
            let u = queue[head]
            head += 1
            for v in range(nodes):
                if residual[u * 18 + v] > 0 and parent[v] < 0:
                    parent[v] = u
                    queue[tail] = v
                    tail += 1
                    if v == sink: break
        if parent[sink] < 0: return False
        var v = sink
        while v != source:
            let u = parent[v]
            residual[u * 18 + v] -= 1
            residual[v * 18 + u] += 1
            v = u
    return True

fn th_condition_three(inner: InlineArray[Bool, 64], degree: InlineArray[Int, 8], n: Int) -> Bool:
    var mask_size = InlineArray[Int, 256](fill=0)
    for mask in range(1, 1 << n): mask_size[mask] = mask_size[mask >> 1] + (mask & 1)
    for start in range(n):
        var dp = InlineArray[UInt8, 2048](fill=255)
        dp[(1 << start) * 8 + start] = 1 if degree[start] >= 3 else 0
        for mask in range(1 << n):
            if (mask & (1 << start)) == 0: continue
            for last in range(start, n):
                let used = Int(dp[mask * 8 + last])
                if used == 255: continue
                if mask_size[mask] >= 3 and inner[last * 8 + start] and used < 3: return False
                for next in range(start + 1, n):
                    let bit = 1 << next
                    if (mask & bit) != 0 or not inner[last * 8 + next]: continue
                    let next_mask = mask | bit
                    let candidate = used + (1 if degree[next] >= 3 else 0)
                    if candidate < Int(dp[next_mask * 8 + next]): dp[next_mask * 8 + next] = UInt8(candidate)
    return True

@export("thomassen_convex_drawing_extendibility")
fn thomassen_convex_drawing_extendibility(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > INPUT_MAX: return -1
    let n0 = input[0]
    let m0 = input[1]
    let f0 = input[2]
    let outer0 = input[3]
    let sides0 = input[4]
    if n0 < 3 or n0 > 8 or m0 < n0 or m0 > 18 or m0 > 3 * n0 - 6 or
        f0 < 2 or f0 > 12 or f0 != m0 - n0 + 2 or outer0 < 0 or outer0 >= f0 or
        sides0 < 3 or sides0 > n0: return -1
    let n = Int(n0); let m = Int(m0); let f = Int(f0); let outer_id = Int(outer0); let side_count = Int(sides0)
    var adjacency = InlineArray[Bool, 64](fill=False)
    var edge_u = InlineArray[Int, 18](fill=0)
    var edge_v = InlineArray[Int, 18](fill=0)
    var cursor = 5
    for e in range(m):
        if cursor + 2 > Int(length): return -1
        let u0 = input[cursor]; let v0 = input[cursor + 1]
        cursor += 2
        if u0 < 0 or u0 >= v0 or v0 >= n0: return -1
        let u = Int(u0); let v = Int(v0)
        if adjacency[u * 8 + v] or (e > 0 and (u < edge_u[e-1] or (u == edge_u[e-1] and v <= edge_v[e-1]))): return -1
        adjacency[u * 8 + v] = True; adjacency[v * 8 + u] = True
        edge_u[e] = u; edge_v[e] = v
    var faces = InlineArray[Int, 96](fill=0)
    var widths = InlineArray[Int, 12](fill=0)
    var darts = InlineArray[Int, 64](fill=0)
    for face in range(f):
        if cursor >= Int(length): return -1
        let width0 = input[cursor]; cursor += 1
        if width0 < 3 or width0 > n0 or cursor + Int(width0) > Int(length): return -1
        let width = Int(width0); widths[face] = width
        var row = InlineArray[Bool, 8](fill=False)
        for i in range(width):
            let x0 = input[cursor]; cursor += 1
            if x0 < 0 or x0 >= n0: return -1
            let x = Int(x0)
            if row[x]: return -1
            row[x] = True; faces[face * 8 + i] = x
        for i in range(width):
            let u = faces[face * 8 + i]; let v = faces[face * 8 + (i + 1) % width]
            if not adjacency[u * 8 + v]: return -1
            darts[u * 8 + v] += 1
    if cursor + side_count != Int(length): return -1
    var apex = InlineArray[Int, 8](fill=0)
    for i in range(side_count):
        let pos = input[cursor]; cursor += 1
        if pos < 0 or pos >= widths[outer_id] or (i > 0 and pos <= apex[i-1]): return -1
        apex[i] = Int(pos)
    for e in range(m):
        let u = edge_u[e]; let v = edge_v[e]
        if darts[u * 8 + v] != 1 or darts[v * 8 + u] != 1: return -1
    if not th_connected(adjacency, n, -1): return -1
    for v in range(n):
        if not th_connected(adjacency, n, v): return -1

    var link_adj = InlineArray[Bool, 512](fill=False)
    var link_degree = InlineArray[Int, 64](fill=0)
    for face in range(f):
        for i in range(widths[face]):
            let center = faces[face * 8 + i]
            let before = faces[face * 8 + (i + widths[face] - 1) % widths[face]]
            let after = faces[face * 8 + (i + 1) % widths[face]]
            if before == after: return -1
            link_adj[(center * 8 + before) * 8 + after] = True
            link_adj[(center * 8 + after) * 8 + before] = True
            link_degree[center * 8 + before] += 1; link_degree[center * 8 + after] += 1
    var outer_v = InlineArray[Bool, 8](fill=False)
    var outer_e = InlineArray[Bool, 64](fill=False)
    for i in range(widths[outer_id]):
        let u = faces[outer_id * 8 + i]; let v = faces[outer_id * 8 + (i + 1) % widths[outer_id]]
        outer_v[u] = True; outer_e[u * 8 + v] = True; outer_e[v * 8 + u] = True
    for center in range(n):
        var seed = -1; var incident = 0
        for v in range(n):
            if adjacency[center * 8 + v]:
                if link_degree[center * 8 + v] != 2: return -1
                if seed < 0: seed = v
                incident += 1
            elif link_degree[center * 8 + v] != 0: return -1
        if seed < 0: return -1
        var seen = InlineArray[Bool, 8](fill=False); var stack = InlineArray[Int, 8](fill=0)
        var top = 1; var reached = 0; seen[seed] = True; stack[0] = seed
        while top > 0:
            top -= 1; let v = stack[top]; reached += 1
            for w in range(n):
                if link_adj[(center * 8 + v) * 8 + w] and not seen[w]: seen[w] = True; stack[top] = w; top += 1
        if reached != incident: return -1
    var face_a = InlineArray[Int, 18](fill=-1); var face_b = InlineArray[Int, 18](fill=-1); var face_use = InlineArray[Int, 18](fill=0)
    for face in range(f):
        for i in range(widths[face]):
            let u = faces[face * 8 + i]; let v = faces[face * 8 + (i+1)%widths[face]]
            let lo = u if u < v else v; let hi = v if u < v else u
            var found = -1
            for e in range(m):
                if edge_u[e] == lo and edge_v[e] == hi: found = e; break
            if found < 0 or face_use[found] >= 2: return -1
            if face_use[found] == 0: face_a[found] = face else: face_b[found] = face
            face_use[found] += 1
    for e in range(m):
        if face_use[e] != 2 or face_a[e] == face_b[e]: return -1
    var sides = InlineArray[Bool, 64](fill=False)
    for s in range(side_count):
        var at = apex[s]; let finish = apex[(s+1)%side_count]
        while True:
            sides[s*8+faces[outer_id*8+at]] = True
            if at == finish: break
            at = (at+1)%widths[outer_id]
    var degree = InlineArray[Int, 8](fill=0)
    for u in range(n):
        for v in range(n):
            if adjacency[u*8+v]: degree[u] += 1
    for root in range(n):
        if not outer_v[root] and degree[root] >= 3 and not th_three_outer_paths(adjacency, outer_v, n, root): return 0
    var seen_inner = InlineArray[Bool, 8](fill=False)
    for seed in range(n):
        if outer_v[seed] or seen_inner[seed]: continue
        var border = InlineArray[Bool, 8](fill=False); var stack = InlineArray[Int, 8](fill=0)
        var top = 1; seen_inner[seed] = True; stack[0] = seed
        while top > 0:
            top -= 1; let u = stack[top]
            for v in range(n):
                if not adjacency[u*8+v]: continue
                if outer_v[v]: border[v] = True
                elif not seen_inner[v]: seen_inner[v] = True; stack[top] = v; top += 1
        for s in range(side_count):
            var nonempty = False; var contained = True
            for v in range(n):
                if border[v]: nonempty = True; if not sides[s*8+v]: contained = False
            if nonempty and contained: return 0
    for e in range(m):
        let u = edge_u[e]; let v = edge_v[e]
        if not outer_e[u*8+v]:
            for s in range(side_count):
                if sides[s*8+u] and sides[s*8+v]: return 0
    var inner = InlineArray[Bool, 64](fill=False)
    for e in range(m):
        let u = edge_u[e]; let v = edge_v[e]
        if not outer_e[u*8+v]: inner[u*8+v] = True; inner[v*8+u] = True
    return 1 if th_condition_three(inner, degree, n) else 0
