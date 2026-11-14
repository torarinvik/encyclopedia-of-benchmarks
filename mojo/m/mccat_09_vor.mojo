# Copyright (C) 1996 McGill University.
# Copyright (C) 1996 McCAT System Group.
# Copyright (C) 1996 ACAPS Benchmark Administrator, benadmin@acaps.cs.mcgill.ca.
# Independent bounded geometric profile; see package LICENSE_NOTICE.txt.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

fn vor_cross(a: Int, b: Int, c: Int, x: InlineArray[Int, 8], y: InlineArray[Int, 8]) -> Int:
    return (x[b] - x[a]) * (y[c] - y[a]) - (y[b] - y[a]) * (x[c] - x[a])

fn vor_length(a: Int, b: Int, x: InlineArray[Int, 8], y: InlineArray[Int, 8]) -> Int:
    let dx = x[a] - x[b]
    let dy = y[a] - y[b]
    return dx * dx + dy * dy

fn vor_center(a: Int, b: Int, c: Int, x: InlineArray[Int, 8], y: InlineArray[Int, 8]) -> (Float64, Float64):
    let n1x = Float64(x[b] - x[a])
    let n1y = Float64(y[b] - y[a])
    let n2x = Float64(x[c] - x[b])
    let n2y = Float64(y[c] - y[b])
    let rhs1 = n1x * ((Float64(x[a]) + Float64(x[b])) / 2.0) + n1y * ((Float64(y[a]) + Float64(y[b])) / 2.0)
    let rhs2 = n2x * ((Float64(x[b]) + Float64(x[c])) / 2.0) + n2y * ((Float64(y[b]) + Float64(y[c])) / 2.0)
    let determinant = n1x * n2y - n1y * n2x
    return ((rhs1 * n2y - n1y * rhs2) / determinant, (n1x * rhs2 - rhs1 * n2x) / determinant)

@export("mccat_09_vor")
fn mccat_09_vor(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 17: return -1
    let raw_count = input[0]
    if raw_count < 3 or raw_count > 8 or Int(length) != 1 + 2 * Int(raw_count): return -1
    let count = Int(raw_count)
    var x = InlineArray[Int, 8](fill=0)
    var y = InlineArray[Int, 8](fill=0)
    for i in range(count):
        let px = input[1 + 2 * i]
        let py = input[2 + 2 * i]
        if px < -4 or px > 4 or py < -4 or py > 4: return -1
        x[i] = Int(px)
        y[i] = Int(py)
        for j in range(i):
            if x[i] == x[j] and y[i] == y[j]: return -1
    for i in range(count):
        for j in range(i + 1, count):
            for k in range(j + 1, count):
                if vor_cross(i, j, k, x, y) == 0: return -1
    for i in range(1, count):
        let px = x[i]
        let py = y[i]
        var j = i
        while j > 0 and (px < x[j - 1] or (px == x[j - 1] and py < y[j - 1])):
            x[j] = x[j - 1]
            y[j] = y[j - 1]
            j -= 1
        x[j] = px
        y[j] = py
    var hull = InlineArray[Int, 16](fill=0)
    var size = 0
    for i in range(count):
        while size >= 2 and vor_cross(hull[size - 2], hull[size - 1], i, x, y) <= 0: size -= 1
        hull[size] = i
        size += 1
    let boundary = size + 1
    var i = count - 2
    while i >= 0:
        while size >= boundary and vor_cross(hull[size - 2], hull[size - 1], i, x, y) <= 0: size -= 1
        hull[size] = i
        size += 1
        i -= 1
    size -= 1
    if size < 3 or size > 8: return -1
    while size > 3:
        var radii = InlineArray[Float64, 8](fill=0.0)
        var angles = InlineArray[Float64, 8](fill=0.0)
        for j in range(size):
            let a = hull[(j + size - 1) % size]
            let b = hull[j]
            let c = hull[(j + 1) % size]
            let (cx, cy) = vor_center(a, b, c, x, y)
            let dx = Float64(x[b]) - cx
            let dy = Float64(y[b]) - cy
            radii[j] = dx * dx + dy * dy
            let ax = Float64(x[a] - x[b])
            let ay = Float64(y[a] - y[b])
            let bx = Float64(x[c] - x[b])
            let by = Float64(y[c] - y[b])
            let dot = ax * bx + ay * by
            let cosine_squared = dot * dot / ((ax * ax + ay * ay) * (bx * bx + by * by))
            angles[j] = -cosine_squared if dot < 0.0 else cosine_squared
            for k in range(j):
                if radii[j] == radii[k] and angles[j] == angles[k]: return -1
        var best = 0
        for j in range(1, size):
            if radii[j] > radii[best] or (radii[j] == radii[best] and angles[j] < angles[best]): best = j
        for j in range(best, size - 1): hull[j] = hull[j + 1]
        size -= 1
    let a = hull[0]
    let b = hull[1]
    let c = hull[2]
    var opposite = a
    var u = b
    var v = c
    var longest = vor_length(b, c, x, y)
    let side_b = vor_length(a, c, x, y)
    if side_b > longest:
        longest = side_b
        opposite = b
        u = a
        v = c
    let side_c = vor_length(a, b, x, y)
    if side_c > longest:
        longest = side_c
        opposite = c
        u = a
        v = b
    let dot = (x[u] - x[opposite]) * (x[v] - x[opposite]) + (y[u] - y[opposite]) * (y[v] - y[opposite])
    var cx: Float64 = 0.0
    var cy: Float64 = 0.0
    var radius: Float64 = 0.0
    if dot < 0:
        cx = (Float64(x[u]) + Float64(x[v])) / 2.0
        cy = (Float64(y[u]) + Float64(y[v])) / 2.0
        radius = sqrt(Float64(longest)) / 2.0
    else:
        let (center_x, center_y) = vor_center(a, b, c, x, y)
        cx = center_x
        cy = center_y
        let dx = Float64(x[a]) - cx
        let dy = Float64(y[a]) - cy
        radius = sqrt(dx * dx + dy * dy)
    let ix = Int(cx)
    let iy = Int(cy)
    let cents = Int(radius * 100.0 + 0.5)
    if ix < -1024 or ix > 1024 or iy < -1024 or iy > 1024 or cents < 0 or cents >= 200000: return -1
    return Int64(((ix + 1024) * 2049 + (iy + 1024)) * 200000 + cents)
