# Clean-room fixed-embedding criterion checker from Encyclopedia Chapter 655.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime N = 8
comptime M = 18
comptime F = 12
comptime INPUT_MAX = 55

@fieldwise_init
struct ClusterGraph(Copyable):
    var n: Int
    var c: Int
    var m: Int
    var f: Int
    var outer_u: Int
    var outer_v: Int
    var outer_face: Int
    var degree: InlineArray[Int, 8]
    var masks: InlineArray[Int, 8]
    var edge_u: InlineArray[Int, 18]
    var edge_v: InlineArray[Int, 18]
    var rotation: InlineArray[Int, 64]
    var face_of: InlineArray[Int, 64]
    var adjacent: InlineArray[Bool, 64]

fn cluster_root(inout parent: InlineArray[Int, 12], start: Int) -> Int:
    var x = start
    while parent[x] != x:
        parent[x] = parent[parent[x]]
        x = parent[x]
    return x

fn cluster_connected(g: ClusterGraph, mask: Int) -> Bool:
    var start = -1
    var expected = 0
    for v in range(g.n):
        if (mask >> v) & 1 != 0:
            if start < 0: start = v
            expected += 1
    if expected <= 1: return True
    var seen = InlineArray[Bool, 8](fill=False)
    var queue = InlineArray[Int, 8](fill=0)
    var head = 0
    var tail = 1
    seen[start] = True
    queue[0] = start
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(g.n):
            if (mask >> v) & 1 != 0 and g.adjacent[8 * u + v] and not seen[v]:
                seen[v] = True
                queue[tail] = v
                tail += 1
    return tail == expected

fn cluster_parse(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int,
        inout g: ClusterGraph) -> Bool:
    if length < 4 or length > INPUT_MAX: return False
    let n64 = input[0]
    let c64 = input[1]
    if n64 < 3 or n64 > N or c64 < 0 or c64 > n64 - 2: return False
    g.n = Int(n64)
    g.c = Int(c64)
    if input[2] < 0 or input[2] >= n64 or input[3] < 0 or input[3] >= n64 or input[2] == input[3]: return False
    g.outer_u = Int(input[2])
    g.outer_v = Int(input[3])
    var offset = 4
    var degree_sum = 0
    for u in range(g.n):
        if offset >= length: return False
        let d64 = input[offset]
        offset += 1
        if d64 < 1 or d64 >= n64 or offset + Int(d64) > length: return False
        let d = Int(d64)
        g.degree[u] = d
        degree_sum += d
        var row_seen = InlineArray[Bool, 8](fill=False)
        for i in range(d):
            let raw = input[offset]
            offset += 1
            if raw < 0 or raw >= n64 or raw == u: return False
            let v = Int(raw)
            if row_seen[v]: return False
            row_seen[v] = True
            g.rotation[8 * u + i] = v
            g.adjacent[8 * u + v] = True
    if degree_sum % 2 != 0 or offset + g.c != length: return False
    g.m = degree_sum // 2
    if g.m < g.n - 1 or g.m > M or not g.adjacent[8 * g.outer_u + g.outer_v]: return False
    var edge_count = 0
    for u in range(g.n):
        for v in range(g.n):
            if g.adjacent[8 * u + v] != g.adjacent[8 * v + u]: return False
            if u < v and g.adjacent[8 * u + v]:
                g.edge_u[edge_count] = u
                g.edge_v[edge_count] = v
                edge_count += 1
    if edge_count != g.m: return False
    let full = (1 << g.n) - 1
    for i in range(g.c):
        let raw = input[offset + i]
        if raw <= 0 or raw >= full: return False
        let mask = Int(raw)
        var bits = 0
        for v in range(g.n): bits += (mask >> v) & 1
        if bits < 2: return False
        for j in range(i):
            if g.masks[j] == mask: return False
            let common = g.masks[j] & mask
            if common != 0 and common != g.masks[j] and common != mask: return False
        g.masks[i] = mask
        if not cluster_connected(g, mask): return False
    if not cluster_connected(g, full): return False
    for i in range(64): g.face_of[i] = -1
    g.f = 0
    for e in range(g.m):
        for side in range(2):
            let su = if side == 0: g.edge_u[e] else: g.edge_v[e]
            let sv = if side == 0: g.edge_v[e] else: g.edge_u[e]
            if g.face_of[8 * su + sv] >= 0: continue
            if g.f >= F: return False
            var local = InlineArray[Bool, 64](fill=False)
            var u = su
            var v = sv
            var steps = 0
            while True:
                if local[8 * u + v] or g.face_of[8 * u + v] >= 0: return False
                local[8 * u + v] = True
                g.face_of[8 * u + v] = g.f
                var at = -1
                for i in range(g.degree[v]):
                    if g.rotation[8 * v + i] == u: at = i
                if at < 0: return False
                let next = g.rotation[8 * v + (at + 1) % g.degree[v]]
                u = v
                v = next
                if u == su and v == sv: break
                steps += 1
                if steps > 2 * g.m: return False
            g.f += 1
    if g.f != g.m - g.n + 2: return False
    for u in range(g.n):
        for v in range(g.n):
            if g.adjacent[8 * u + v] and g.face_of[8 * u + v] < 0: return False
    g.outer_face = g.face_of[8 * g.outer_u + g.outer_v]
    return g.outer_face >= 0

fn cluster_solve(g: ClusterGraph) -> Int64:
    for ci in range(g.c):
        var parent = InlineArray[Int, 12](fill=0)
        for f in range(g.f): parent[f] = f
        let mask = g.masks[ci]
        for e in range(g.m):
            let u = g.edge_u[e]
            let v = g.edge_v[e]
            if (mask >> u) & 1 != 0 and (mask >> v) & 1 != 0: continue
            let a = cluster_root(parent, g.face_of[8 * u + v])
            let b = cluster_root(parent, g.face_of[8 * v + u])
            parent[a] = b
        let outside = cluster_root(parent, g.outer_face)
        for v in range(g.n):
            if (mask >> v) & 1 != 0: continue
            var incident = False
            for u in range(g.n):
                if g.adjacent[8 * v + u]:
                    incident = True
                    if cluster_root(parent, g.face_of[8 * v + u]) != outside: return 0
            if not incident: return -1
        for e in range(g.m):
            let u = g.edge_u[e]
            let v = g.edge_v[e]
            if (mask >> u) & 1 != 0 and (mask >> v) & 1 != 0: continue
            if cluster_root(parent, g.face_of[8 * u + v]) != outside: return 0
    return 1

@export("c_connected_clustered_embedding_condition")
fn c_connected_clustered_embedding_condition(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(INPUT_MAX): return -1
    var g = ClusterGraph(0, 0, 0, 0, 0, 0, 0,
        InlineArray[Int, 8](fill=0), InlineArray[Int, 8](fill=0),
        InlineArray[Int, 18](fill=0), InlineArray[Int, 18](fill=0),
        InlineArray[Int, 64](fill=0), InlineArray[Int, 64](fill=-1),
        InlineArray[Bool, 64](fill=False))
    if not cluster_parse(input, Int(length), g): return -1
    return cluster_solve(g)
