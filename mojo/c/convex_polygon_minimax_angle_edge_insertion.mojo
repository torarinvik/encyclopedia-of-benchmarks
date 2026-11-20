from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime CMAI_MIN_N = 3
comptime CMAI_MAX_N = 4
comptime CMAI_MAX_LENGTH = 10
comptime CMAI_MAX_ANGLES = 12

@fieldwise_init
struct CmaiPoint(Copyable):
    var x: Int64
    var y: Int64

@fieldwise_init
struct CmaiAngle(Copyable):
    var a: Int
    var b: Int
    var c: Int
    var vertex: Int

@fieldwise_init
struct CmaiTriangle(Copyable):
    var a: Int
    var b: Int
    var c: Int

fn cmai_orient(points: InlineArray[CmaiPoint, CMAI_MAX_N], a: Int, b: Int, c: Int) -> Int64:
    (points[b].x - points[a].x) * (points[c].y - points[a].y) - (points[b].y - points[a].y) * (points[c].x - points[a].x)

fn cmai_angle_dot(points: InlineArray[CmaiPoint, CMAI_MAX_N], angle: CmaiAngle) -> Int64:
    var vertices = InlineArray[Int, 3](fill=0)
    vertices[0] = angle.a
    vertices[1] = angle.b
    vertices[2] = angle.c
    let center = vertices[angle.vertex]
    var endpoints = InlineArray[Int, 2](fill=0)
    var used = 0
    for i in range(3):
        if vertices[i] != center:
            endpoints[used] = vertices[i]
            used += 1
    let ux = points[endpoints[0]].x - points[center].x
    let uy = points[endpoints[0]].y - points[center].y
    let vx = points[endpoints[1]].x - points[center].x
    let vy = points[endpoints[1]].y - points[center].y
    ux * vx + uy * vy

fn cmai_angle_den(points: InlineArray[CmaiPoint, CMAI_MAX_N], angle: CmaiAngle) -> Int64:
    var vertices = InlineArray[Int, 3](fill=0)
    vertices[0] = angle.a
    vertices[1] = angle.b
    vertices[2] = angle.c
    let center = vertices[angle.vertex]
    var endpoints = InlineArray[Int, 2](fill=0)
    var used = 0
    for i in range(3):
        if vertices[i] != center:
            endpoints[used] = vertices[i]
            used += 1
    let ux = points[endpoints[0]].x - points[center].x
    let uy = points[endpoints[0]].y - points[center].y
    let vx = points[endpoints[1]].x - points[center].x
    let vy = points[endpoints[1]].y - points[center].y
    (ux * ux + uy * uy) * (vx * vx + vy * vy)

fn cmai_angle_cmp(points: InlineArray[CmaiPoint, CMAI_MAX_N], left: CmaiAngle, right: CmaiAngle) -> Int:
    let d1 = cmai_angle_dot(points, left)
    let z1 = cmai_angle_den(points, left)
    let d2 = cmai_angle_dot(points, right)
    let z2 = cmai_angle_den(points, right)
    if d1 == 0 or d2 == 0:
        if d1 == d2: return 0
        if d1 == 0: return 1 if d2 > 0 else -1
        return -1 if d1 > 0 else 1
    if (d1 < 0) != (d2 < 0): return 1 if d1 < 0 else -1
    let lhs = d1 * d1 * z2
    let rhs = d2 * d2 * z1
    if lhs == rhs: return 0
    if d1 > 0: return -1 if lhs > rhs else 1
    return 1 if lhs > rhs else -1

fn cmai_triangle_max(points: InlineArray[CmaiPoint, CMAI_MAX_N], triangle: CmaiTriangle) -> CmaiAngle:
    var v = InlineArray[Int, 3](fill=0)
    v[0] = triangle.a
    v[1] = triangle.b
    v[2] = triangle.c
    for i in range(3):
        for j in range(i + 1, 3):
            if v[i] > v[j]:
                let temp = v[i]
                v[i] = v[j]
                v[j] = temp
    var best = CmaiAngle(v[0], v[1], v[2], 0)
    for vertex in range(1, 3):
        let candidate = CmaiAngle(v[0], v[1], v[2], vertex)
        if cmai_angle_cmp(points, candidate, best) > 0: best = candidate
    best

fn cmai_triangulation_max(points: InlineArray[CmaiPoint, CMAI_MAX_N], triangles: InlineArray[CmaiTriangle, 2], count: Int) -> CmaiAngle:
    var best = cmai_triangle_max(points, triangles[0])
    for i in range(1, count):
        let candidate = cmai_triangle_max(points, triangles[i])
        if cmai_angle_cmp(points, candidate, best) > 0: best = candidate
    best

fn cmai_angle_rank(points: InlineArray[CmaiPoint, CMAI_MAX_N], n: Int, target: CmaiAngle) -> Int64:
    var distinct_lower = InlineArray[CmaiAngle, CMAI_MAX_ANGLES](fill=CmaiAngle(0, 0, 0, 0))
    var count = 0
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                for vertex in range(3):
                    let candidate = CmaiAngle(a, b, c, vertex)
                    if cmai_angle_cmp(points, candidate, target) >= 0: continue
                    var seen = False
                    for i in range(count):
                        if cmai_angle_cmp(points, candidate, distinct_lower[i]) == 0: seen = True
                    if not seen:
                        distinct_lower[count] = candidate
                        count += 1
    Int64(count + 1)

fn cmai_proper_crossing(points: InlineArray[CmaiPoint, CMAI_MAX_N], a: Int, b: Int, c: Int, d: Int) -> Bool:
    cmai_orient(points, a, b, c) * cmai_orient(points, a, b, d) < 0 and cmai_orient(points, c, d, a) * cmai_orient(points, c, d, b) < 0

fn cmai_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 1 or length > CMAI_MAX_LENGTH: return -1
    if input[0] < CMAI_MIN_N or input[0] > CMAI_MAX_N: return -1
    let n = Int(input[0])
    if length != 1 + 2 * n: return -1
    var points = InlineArray[CmaiPoint, CMAI_MAX_N](fill=CmaiPoint(0, 0))
    for i in range(n):
        points[i] = CmaiPoint(input[1 + 2 * i], input[2 + 2 * i])
        if points[i].x < -16 or points[i].x > 16 or points[i].y < -16 or points[i].y > 16: return -1
        for j in range(i):
            if points[i].x == points[j].x and points[i].y == points[j].y: return -1
    var area2: Int64 = 0
    for i in range(n):
        let next = (i + 1) % n
        area2 += points[i].x * points[next].y - points[i].y * points[next].x
    if area2 == 0: return -1
    let orientation: Int64 = 1 if area2 > 0 else -1
    for a in range(n):
        for b in range(a + 1, n):
            for c in range(b + 1, n):
                if cmai_orient(points, a, b, c) == 0: return -1
    for edge in range(n):
        let next = (edge + 1) % n
        for vertex in range(n):
            if vertex != edge and vertex != next and orientation * cmai_orient(points, edge, next, vertex) <= 0: return -1

    var fan = InlineArray[CmaiTriangle, 2](fill=CmaiTriangle(0, 0, 0))
    fan[0] = CmaiTriangle(0, 1, 2)
    fan[1] = CmaiTriangle(0, 2, 3)
    var worst = cmai_triangle_max(points, CmaiTriangle(0, 1, 2))
    if n == 4: worst = cmai_triangulation_max(points, fan, 2)
    if n == 4:
        var accepted = False
        for ti in range(2):
            if accepted: break
            var vertices = InlineArray[Int, 3](fill=0)
            vertices[0] = fan[ti].a
            vertices[1] = fan[ti].b
            vertices[2] = fan[ti].c
            for vertex in range(3):
                if accepted: break
                let candidate = CmaiAngle(vertices[0], vertices[1], vertices[2], vertex)
                if cmai_angle_cmp(points, candidate, worst) != 0: continue
                let q = vertices[vertex]
                var opposite = InlineArray[Int, 2](fill=0)
                var used = 0
                var s = -1
                for i in range(3):
                    if i != vertex:
                        opposite[used] = vertices[i]
                        used += 1
                for point in range(4):
                    if point != vertices[0] and point != vertices[1] and point != vertices[2]: s = point
                if not cmai_proper_crossing(points, q, s, opposite[0], opposite[1]): continue
                var inserted = InlineArray[CmaiTriangle, 2](fill=CmaiTriangle(0, 0, 0))
                inserted[0] = CmaiTriangle(q, s, opposite[0])
                inserted[1] = CmaiTriangle(q, s, opposite[1])
                let replacement = cmai_triangulation_max(points, inserted, 2)
                if cmai_angle_cmp(points, replacement, worst) < 0:
                    worst = replacement
                    accepted = True
    cmai_angle_rank(points, n, worst)

@export("convex_polygon_minimax_angle_edge_insertion")
fn convex_polygon_minimax_angle_edge_insertion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(CMAI_MAX_LENGTH): return -1
    cmai_impl(input, Int(length))
