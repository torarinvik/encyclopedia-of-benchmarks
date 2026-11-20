from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import floor, isfinite
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_V = 24
comptime MAX_F = 8
comptime MAX_D = 8
comptime MAX_E = 32
comptime MAX_IN = 122
comptime MAX_OUT = 386

fn cc_face_index(f: Int, i: Int) -> Int:
    return f * MAX_D + i

fn cc_integer(value: Float64, low: Int, high: Int) -> Int:
    if not isfinite(value) or floor(value) != value or value < Float64(low) or value > Float64(high): return -1
    return Int(value)

fn cc_mean(values: InlineArray[Float64, MAX_D], count: Int) -> Float64:
    var scale: Float64 = 0.0
    for i in range(count):
        if abs(values[i]) > scale: scale = abs(values[i])
    if scale == 0.0: return 0.0
    var total: Float64 = 0.0
    for i in range(count): total += values[i] / scale
    return (total / Float64(count)) * scale

fn cc_midpoint(a: Float64, b: Float64) -> Float64:
    let scale = max(abs(a), abs(b))
    if scale == 0.0: return 0.0
    return ((a / scale + b / scale) * 0.5) * scale

fn cc_average4(a: Float64, b: Float64, c: Float64, d: Float64) -> Float64:
    let scale = max(max(abs(a), abs(b)), max(abs(c), abs(d)))
    if scale == 0.0: return 0.0
    return ((a / scale + b / scale + c / scale + d / scale) * 0.25) * scale

fn cc_compute(input: UnsafePointer[Float64, ImmutAnyOrigin], length: Int,
              inout staged: InlineArray[Float64, MAX_OUT]) -> Int:
    for i in range(length):
        if not isfinite(input[i]): return -1
    let nv = cc_integer(input[0], 0, MAX_V)
    let nf = cc_integer(input[1], 0, MAX_F)
    if nv < 0 or nf < 0: return -1
    if (nv == 0 or nf == 0) and not (nv == 0 and nf == 0 and length == 2): return -1

    var x = InlineArray[Float64, MAX_V](fill=0.0)
    var y = InlineArray[Float64, MAX_V](fill=0.0)
    var degree = InlineArray[Int, MAX_F](fill=0)
    var face = InlineArray[Int, MAX_F * MAX_D](fill=0)
    var position = 2
    if position + 2 * nv > length: return -1
    for v in range(nv):
        x[v] = input[position]
        y[v] = input[position + 1]
        position += 2

    var eu = InlineArray[Int, MAX_E](fill=0)
    var ev = InlineArray[Int, MAX_E](fill=0)
    var ef0 = InlineArray[Int, MAX_E](fill=0)
    var ef1 = InlineArray[Int, MAX_E](fill=0)
    var uses = InlineArray[Int, MAX_E](fill=0)
    var edge_count = 0
    for f in range(nf):
        if position >= length: return -1
        degree[f] = cc_integer(input[position], 3, MAX_D)
        position += 1
        if degree[f] < 0 or position + degree[f] > length: return -1
        for i in range(degree[f]):
            let value = cc_integer(input[position], 0, nv - 1)
            position += 1
            if value < 0: return -1
            for j in range(i):
                if face[cc_face_index(f, j)] == value: return -1
            face[cc_face_index(f, i)] = value
        for i in range(degree[f]):
            let a = face[cc_face_index(f, i)]
            let b = face[cc_face_index(f, (i + 1) % degree[f])]
            let u = min(a, b)
            let v = max(a, b)
            var found = -1
            for e in range(edge_count):
                if eu[e] == u and ev[e] == v:
                    found = e
                    break
            if found < 0:
                if edge_count == MAX_E: return -1
                eu[edge_count] = u
                ev[edge_count] = v
                ef0[edge_count] = f
                ef1[edge_count] = 0
                uses[edge_count] = 1
                edge_count += 1
            else:
                if uses[found] != 1 or ef0[found] == f: return -1
                uses[found] = 2
                ef1[found] = f
    if position != length: return -1
    for e in range(edge_count):
        if uses[e] != 2: return -1

    for vertex in range(nv):
        var valence = 0
        for e in range(edge_count):
            if eu[e] == vertex or ev[e] == vertex: valence += 1
        var link_a = InlineArray[Int, MAX_F](fill=0)
        var link_b = InlineArray[Int, MAX_F](fill=0)
        var links = 0
        for f in range(nf):
            for i in range(degree[f]):
                if face[cc_face_index(f, i)] == vertex:
                    let a = face[cc_face_index(f, (i + degree[f] - 1) % degree[f])]
                    let b = face[cc_face_index(f, (i + 1) % degree[f])]
                    let lo = min(a, b)
                    let hi = max(a, b)
                    for j in range(links):
                        if min(link_a[j], link_b[j]) == lo and max(link_a[j], link_b[j]) == hi: return -1
                    link_a[links] = a
                    link_b[links] = b
                    links += 1
        if valence < 3 or links != valence: return -1
        var reached = InlineArray[Bool, MAX_V](fill=False)
        reached[link_a[0]] = True
        var changed = True
        while changed:
            changed = False
            for i in range(links):
                if reached[link_a[i]] and not reached[link_b[i]]:
                    reached[link_b[i]] = True
                    changed = True
                if reached[link_b[i]] and not reached[link_a[i]]:
                    reached[link_a[i]] = True
                    changed = True
        var node_degree = InlineArray[Int, MAX_V](fill=0)
        for i in range(links):
            node_degree[link_a[i]] += 1
            node_degree[link_b[i]] += 1
        var nodes = 0
        for u in range(nv):
            if node_degree[u] != 0:
                nodes += 1
                if node_degree[u] != 2 or not reached[u]: return -1
        if nodes < 3: return -1

    for i in range(1, edge_count):
        let u = eu[i]
        let v = ev[i]
        let f0 = ef0[i]
        let f1 = ef1[i]
        var j = i
        while j > 0 and (eu[j - 1] > u or (eu[j - 1] == u and ev[j - 1] > v)):
            eu[j] = eu[j - 1]
            ev[j] = ev[j - 1]
            ef0[j] = ef0[j - 1]
            ef1[j] = ef1[j - 1]
            j -= 1
        eu[j] = u
        ev[j] = v
        ef0[j] = f0
        ef1[j] = f1

    var face_x = InlineArray[Float64, MAX_F](fill=0.0)
    var face_y = InlineArray[Float64, MAX_F](fill=0.0)
    for f in range(nf):
        var vx = InlineArray[Float64, MAX_D](fill=0.0)
        var vy = InlineArray[Float64, MAX_D](fill=0.0)
        for i in range(degree[f]):
            vx[i] = x[face[cc_face_index(f, i)]]
            vy[i] = y[face[cc_face_index(f, i)]]
        face_x[f] = cc_mean(vx, degree[f])
        face_y[f] = cc_mean(vy, degree[f])

    var out = 0
    let new_vertices = nv + edge_count + nf
    var new_faces = 0
    for f in range(nf): new_faces += degree[f]
    staged[out] = Float64(new_vertices); out += 1
    staged[out] = Float64(new_faces); out += 1
    for vertex in range(nv):
        var fxs = InlineArray[Float64, MAX_F](fill=0.0)
        var fys = InlineArray[Float64, MAX_F](fill=0.0)
        var rx = InlineArray[Float64, MAX_F](fill=0.0)
        var ry = InlineArray[Float64, MAX_F](fill=0.0)
        var nfi = 0
        var nei = 0
        for f in range(nf):
            for i in range(degree[f]):
                if face[cc_face_index(f, i)] == vertex:
                    fxs[nfi] = face_x[f]
                    fys[nfi] = face_y[f]
                    nfi += 1
                    break
        for e in range(edge_count):
            if eu[e] == vertex or ev[e] == vertex:
                rx[nei] = cc_midpoint(x[eu[e]], x[ev[e]])
                ry[nei] = cc_midpoint(y[eu[e]], y[ev[e]])
                nei += 1
        let fa_x = cc_mean(fxs, nfi)
        let fa_y = cc_mean(fys, nfi)
        let ra_x = cc_mean(rx, nei)
        let ra_y = cc_mean(ry, nei)
        let sx = max(abs(x[vertex]), max(abs(fa_x), abs(ra_x)))
        let sy = max(abs(y[vertex]), max(abs(fa_y), abs(ra_y)))
        staged[out] = if sx == 0.0: 0.0 else: ((fa_x/sx + 2.0*ra_x/sx + Float64(nei-3)*(x[vertex]/sx)) / Float64(nei))*sx
        out += 1
        staged[out] = if sy == 0.0: 0.0 else: ((fa_y/sy + 2.0*ra_y/sy + Float64(nei-3)*(y[vertex]/sy)) / Float64(nei))*sy
        out += 1
    for e in range(edge_count):
        staged[out] = cc_average4(x[eu[e]], x[ev[e]], face_x[ef0[e]], face_x[ef1[e]]); out += 1
        staged[out] = cc_average4(y[eu[e]], y[ev[e]], face_y[ef0[e]], face_y[ef1[e]]); out += 1
    for f in range(nf):
        staged[out] = face_x[f]; out += 1
        staged[out] = face_y[f]; out += 1
    for f in range(nf):
        for i in range(degree[f]):
            let vertex = face[cc_face_index(f, i)]
            let next = face[cc_face_index(f, (i + 1) % degree[f])]
            let prev = face[cc_face_index(f, (i + degree[f] - 1) % degree[f])]
            let u1 = min(vertex, next); let v1 = max(vertex, next)
            let u2 = min(prev, vertex); let v2 = max(prev, vertex)
            var en = 0; var ep = 0
            for e in range(edge_count):
                if eu[e] == u1 and ev[e] == v1: en = e
                if eu[e] == u2 and ev[e] == v2: ep = e
            staged[out] = Float64(vertex); out += 1
            staged[out] = Float64(nv + en); out += 1
            staged[out] = Float64(nv + edge_count + f); out += 1
            staged[out] = Float64(nv + ep); out += 1
    return out
}

@export("catmull_clark_subdivision")
fn catmull_clark_subdivision(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 2 or length > MAX_IN: return -1
    var staged = InlineArray[Float64, MAX_OUT](fill=0.0)
    let result = cc_compute(input, Int(length), inout staged)
    if result < 0: return -1
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < result: return -2
    for i in range(result): output[i] = staged[i]
    return Int64(result)
