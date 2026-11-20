# Clean-room bounded port of the Chapter 654 cyclic wedge subprocedure.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime SW_N = 8
comptime SW_M = 18
comptime SW_F = 12
comptime SW_INPUT_MAX = 55
comptime SW_OUTPUT_MAX = 128

@fieldwise_init
struct WedgeGraph(Copyable):
    var n: Int
    var k: Int
    var b: Int
    var m: Int
    var f: Int
    var center: Int
    var outer_id: Int
    var outer: InlineArray[Int, 8]
    var degree: InlineArray[Int, 8]
    var rotation: InlineArray[Int, 64]
    var permutation: InlineArray[Int, 8]
    var adjacent: InlineArray[Bool, 64]
    var edge_u: InlineArray[Int, 18]
    var edge_v: InlineArray[Int, 18]
    var face_length: InlineArray[Int, 12]
    var faces: InlineArray[Int, 96]
    var dart_face: InlineArray[Int, 64]

@fieldwise_init
struct WedgeResult(Copyable):
    var valid: Bool
    var count: Int
    var words: InlineArray[Int64, 16]

fn sw_connected(g: WedgeGraph, removed_a: Int, removed_b: Int) -> Bool:
    var start = -1
    var expected = 0
    for v in range(g.n):
        if v != removed_a and v != removed_b:
            if start < 0: start = v
            expected += 1
    if expected <= 1: return True
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
        for v in range(g.n):
            if v != removed_a and v != removed_b and g.adjacent[8 * u + v] and not seen[v]:
                seen[v] = True
                stack[top] = v
                top += 1
    return count == expected

fn sw_face_walk(g: WedgeGraph, first: Int, second: Int) -> InlineArray[Int, 37]:
    var result = InlineArray[Int, 37](fill=0)
    var seen = InlineArray[Bool, 64](fill=False)
    var u = first
    var v = second
    var length = 0
    for _ in range(2 * g.m):
        if not g.adjacent[8 * u + v] or seen[8 * u + v]:
            result[0] = -1
            return result
        seen[8 * u + v] = True
        result[length + 1] = u
        length += 1
        var at = -1
        for i in range(g.degree[v]):
            if g.rotation[8 * v + i] == u: at = i
        if at < 0:
            result[0] = -1
            return result
        let next = g.rotation[8 * v + (at + 1) % g.degree[v]]
        u = v
        v = next
        if u == first and v == second:
            result[0] = length
            return result
    result[0] = -1
    return result

fn sw_same_cyclic(a: InlineArray[Int, 8], a_start: Int, b: InlineArray[Int, 96], b_start: Int, length: Int) -> Bool:
    for shift in range(length):
        var equal = True
        for i in range(length):
            if a[(a_start + i) % 8] != b[b_start + ((i + shift) % 8)]: equal = False
        if equal: return True
    return False

fn sw_parse(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int, inout g: WedgeGraph) -> Bool:
    if length < 3 or length > SW_INPUT_MAX: return False
    let n0 = input[0]
    let k0 = input[1]
    let b0 = input[2]
    if n0 < 4 or n0 > SW_N or k0 < 3 or k0 > SW_N or (n0 - 1) % k0 != 0 or b0 < k0 or b0 > n0 or b0 % k0 != 0: return False
    g.n = Int(n0); g.k = Int(k0); g.b = Int(b0)
    var offset = 3
    if offset + g.b > length: return False
    var outer_seen = InlineArray[Bool, 8](fill=False)
    for i in range(g.b):
        let raw = input[offset]
        offset += 1
        if raw < 0 or raw >= n0 or outer_seen[Int(raw)]: return False
        g.outer[i] = Int(raw)
        outer_seen[Int(raw)] = True
    var degree_sum = 0
    for u in range(g.n):
        if offset >= length: return False
        let raw_degree = input[offset]
        offset += 1
        if raw_degree < 3 or raw_degree >= n0 or offset + Int(raw_degree) > length: return False
        let d = Int(raw_degree)
        g.degree[u] = d
        degree_sum += d
        var row_seen = InlineArray[Bool, 8](fill=False)
        for i in range(d):
            let raw = input[offset]
            offset += 1
            if raw < 0 or raw >= n0 or raw == u or row_seen[Int(raw)]: return False
            row_seen[Int(raw)] = True
            g.rotation[8 * u + i] = Int(raw)
            g.adjacent[8 * u + Int(raw)] = True
    if offset + g.n != length or degree_sum % 2 != 0: return False
    var permutation_seen = InlineArray[Bool, 8](fill=False)
    for u in range(g.n):
        let raw = input[offset + u]
        if raw < 0 or raw >= n0 or permutation_seen[Int(raw)]: return False
        g.permutation[u] = Int(raw)
        permutation_seen[Int(raw)] = True
    g.m = degree_sum // 2
    if g.m < g.n or g.m > 3 * g.n - 6 or g.m > SW_M: return False
    var edge_count = 0
    for u in range(g.n):
        for v in range(g.n):
            if g.adjacent[8 * u + v] != g.adjacent[8 * v + u]: return False
            if u < v and g.adjacent[8 * u + v]:
                g.edge_u[edge_count] = u
                g.edge_v[edge_count] = v
                edge_count += 1
    if edge_count != g.m or not sw_connected(g, -1, -1): return False
    for u in range(g.n):
        if not sw_connected(g, u, -1): return False
        for v in range(u + 1, g.n):
            if not sw_connected(g, u, v): return False

    for i in range(64): g.dart_face[i] = -1
    g.f = 0
    for e in range(g.m):
        let a = g.edge_u[e]
        let b = g.edge_v[e]
        for direction in range(2):
            let u = if direction == 0: a else: b
            let v = if direction == 0: b else: a
            if g.dart_face[8 * u + v] >= 0: continue
            if g.f >= SW_F: return False
            let walk = sw_face_walk(g, u, v)
            let face_len = walk[0]
            if face_len < 3 or face_len > g.n: return False
            var face_seen = InlineArray[Bool, 8](fill=False)
            for i in range(face_len):
                let x = walk[i + 1]
                let y = walk[(i + 1) % face_len + 1]
                if face_seen[x] or g.dart_face[8 * x + y] >= 0: return False
                face_seen[x] = True
            g.face_length[g.f] = face_len
            for i in range(face_len):
                let x = walk[i + 1]
                let y = walk[(i + 1) % face_len + 1]
                g.faces[8 * g.f + i] = x
                g.dart_face[8 * x + y] = g.f
            g.f += 1
    if g.f != g.m - g.n + 2: return False
    g.outer_id = -1
    for face in range(g.f):
        if g.face_length[face] == g.b and sw_same_cyclic(g.outer, 0, g.faces, face * 8, g.b): g.outer_id = face
    if g.outer_id < 0: return False
    g.center = -1
    var fixed_count = 0
    for v in range(g.n):
        if g.permutation[v] == v:
            g.center = v
            fixed_count += 1
    if fixed_count != 1: return False
    if outer_seen[g.center]: return False
    for v in range(g.n):
        if v == g.center: continue
        var current = g.permutation[v]
        var orbit_length = 1
        while current != v and orbit_length <= g.k:
            current = g.permutation[current]
            orbit_length += 1
        if current != v or orbit_length != g.k: return False
    for v in range(g.n):
        let image = g.permutation[v]
        for w in range(g.n):
            if g.adjacent[8 * v + w] != g.adjacent[8 * image + g.permutation[w]]: return False
        var row_ok = False
        for shift in range(g.degree[image]):
            var equal = True
            for i in range(g.degree[v]):
                if g.permutation[g.rotation[8 * v + i]] != g.rotation[8 * image + (i + shift) % g.degree[image]]: equal = False
            if equal: row_ok = True
        if not row_ok: return False
    let outer_shift = g.b // g.k
    for i in range(g.b):
        if g.permutation[g.outer[i]] != g.outer[(i + outer_shift) % g.b]: return False
    return True

fn sw_solve(g: WedgeGraph) -> WedgeResult:
    var result = WedgeResult(False, 0, InlineArray[Int64, 16](fill=0))
    var distance = InlineArray[Int, 8](fill=-1)
    var queue = InlineArray[Int, 12](fill=0)
    var head = 0
    var tail = 1
    distance[g.center] = 0
    queue[0] = g.center
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(g.n):
            if g.adjacent[8 * u + v] and distance[v] < 0:
                distance[v] = distance[u] + 1
                queue[tail] = v
                tail += 1
    var endpoint = -1
    for i in range(g.b):
        let v = g.outer[i]
        if endpoint < 0 or distance[v] < distance[endpoint] or (distance[v] == distance[endpoint] and v < endpoint): endpoint = v
    if endpoint < 0 or distance[endpoint] <= 0: return result
    var to_endpoint = InlineArray[Int, 8](fill=-1)
    head = 0; tail = 1
    to_endpoint[endpoint] = 0
    queue[0] = endpoint
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(g.n):
            if g.adjacent[8 * u + v] and to_endpoint[v] < 0:
                to_endpoint[v] = to_endpoint[u] + 1
                queue[tail] = v
                tail += 1
    var p1 = InlineArray[Int, 8](fill=0)
    var p2 = InlineArray[Int, 8](fill=0)
    var p0 = InlineArray[Int, 8](fill=0)
    var p1_len = 1
    p1[0] = g.center
    while p1[p1_len - 1] != endpoint and p1_len < SW_N:
        let u = p1[p1_len - 1]
        var choice = -1
        for v in range(g.n):
            if g.adjacent[8 * u + v] and to_endpoint[v] == to_endpoint[u] - 1 and (choice < 0 or v < choice): choice = v
        if choice < 0: return result
        p1[p1_len] = choice
        p1_len += 1
    if p1[p1_len - 1] != endpoint or p1_len - 1 != distance[endpoint]: return result
    let p2_len = p1_len
    for i in range(p1_len): p2[i] = g.permutation[p1[i]]
    let endpoint2 = p2[p2_len - 1]
    if endpoint2 == endpoint: return result
    for i in range(1, p1_len - 1):
        for j in range(1, p2_len):
            if p1[i] == p2[j]: return result
    for i in range(1, p1_len - 1):
        for j in range(g.b):
            if p1[i] == g.outer[j]: return result
    for i in range(1, p2_len - 1):
        for j in range(g.b):
            if p2[i] == g.outer[j]: return result
    var start = -1
    for i in range(g.b):
        if g.outer[i] == endpoint: start = i
    if start < 0: return result
    let p0_len = g.b // g.k + 1
    for i in range(p0_len): p0[i] = g.outer[(start + i) % g.b]
    if p0[p0_len - 1] != endpoint2: return result
    var cycle = InlineArray[Int, 24](fill=0)
    var cycle_len = 0
    for i in range(p1_len):
        cycle[cycle_len] = p1[i]
        cycle_len += 1
    for i in range(1, p0_len):
        cycle[cycle_len] = p0[i]
        cycle_len += 1
    var i = p2_len - 1
    while i > 0:
        i -= 1
        cycle[cycle_len] = p2[i]
        cycle_len += 1
    if cycle[0] != g.center or cycle[cycle_len - 1] != g.center: return result
    var cycle_vertex = InlineArray[Bool, 8](fill=False)
    var cycle_edge = InlineArray[Bool, 64](fill=False)
    for j in range(cycle_len - 1):
        let u = cycle[j]
        let v = cycle[j + 1]
        if not g.adjacent[8 * u + v] or cycle_vertex[u]: return result
        cycle_vertex[u] = True
        cycle_edge[8 * u + v] = True
        cycle_edge[8 * v + u] = True
    let seed = g.dart_face[8 * p0[1] + p0[0]]
    if seed < 0 or seed == g.outer_id: return result
    var dual = InlineArray[Bool, 144](fill=False)
    var in_face = InlineArray[Bool, 12](fill=False)
    for e in range(g.m):
        let u = g.edge_u[e]
        let v = g.edge_v[e]
        if not cycle_edge[8 * u + v]:
            let a = g.dart_face[8 * u + v]
            let b = g.dart_face[8 * v + u]
            dual[12 * a + b] = True
            dual[12 * b + a] = True
    head = 0; tail = 1
    queue[0] = seed
    in_face[seed] = True
    while head < tail:
        let f = queue[head]
        head += 1
        for other in range(g.f):
            if dual[12 * f + other] and not in_face[other]:
                in_face[other] = True
                queue[tail] = other
                tail += 1
    if in_face[g.outer_id]: return result
    var wedge_vertex = InlineArray[Bool, 8](fill=False)
    for v in range(g.n): wedge_vertex[v] = cycle_vertex[v]
    for f in range(g.f):
        if in_face[f]:
            for j in range(g.face_length[f]): wedge_vertex[g.faces[8 * f + j]] = True
    var vertex_mask = 0
    var edge_mask = 0
    for v in range(g.n):
        if wedge_vertex[v]: vertex_mask |= 1 << v
    for e in range(g.m):
        if wedge_vertex[g.edge_u[e]] and wedge_vertex[g.edge_v[e]]: edge_mask |= 1 << e
    var at = 0
    result.words[at] = Int64(p1_len); at += 1
    for j in range(p1_len): result.words[at] = Int64(p1[j]); at += 1
    result.words[at] = Int64(p2_len); at += 1
    for j in range(p2_len): result.words[at] = Int64(p2[j]); at += 1
    result.words[at] = Int64(p0_len); at += 1
    for j in range(p0_len): result.words[at] = Int64(p0[j]); at += 1
    result.words[at] = Int64(vertex_mask); at += 1
    result.words[at] = Int64(edge_mask); at += 1
    result.count = at
    result.valid = True
    return result

@export("symmetric_drawing_cyclic_wedge")
fn symmetric_drawing_cyclic_wedge(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(SW_INPUT_MAX): return -1
    var g = WedgeGraph(0, 0, 0, 0, 0, 0, 0,
        InlineArray[Int, 8](fill=0), InlineArray[Int, 8](fill=0),
        InlineArray[Int, 64](fill=0), InlineArray[Int, 8](fill=0),
        InlineArray[Bool, 64](fill=False), InlineArray[Int, 18](fill=0),
        InlineArray[Int, 18](fill=0), InlineArray[Int, 12](fill=0),
        InlineArray[Int, 96](fill=0), InlineArray[Int, 64](fill=-1))
    if not sw_parse(input, Int(length), g): return -1
    let result = sw_solve(g)
    if not result.valid: return -1
    let bytes = result.count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(result.count):
        let bits = UInt64(result.words[i])
        for byte in range(8): output[8 * i + byte] = UInt8((bits >> UInt(8 * byte)) & 255)
    return Int64(bytes)
