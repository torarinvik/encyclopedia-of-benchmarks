from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime CPMT_MIN_VERTICES = 3
comptime CPMT_MAX_VERTICES = 12
comptime CPMT_MAX_PARSEABLE_LENGTH = 26
comptime CPMT_COORD_LIMIT = 1000

@fieldwise_init
struct CpmtPoint(Copyable):
    var x: Int64
    var y: Int64

fn cpmt_cross(a: CpmtPoint, b: CpmtPoint, c: CpmtPoint) -> Int64:
    (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

fn cpmt_squared_length(points: InlineArray[CpmtPoint, CPMT_MAX_VERTICES], left: Int, right: Int) -> Int64:
    let dx = points[left].x - points[right].x
    let dy = points[left].y - points[right].y
    dx * dx + dy * dy

fn cpmt_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Int64:
    if length < 1 or length > CPMT_MAX_PARSEABLE_LENGTH: return -1
    if input[0] < CPMT_MIN_VERTICES or input[0] > CPMT_MAX_VERTICES: return -1
    let n = Int(input[0])
    if length != 1 + 2 * n: return -1
    var points = InlineArray[CpmtPoint, CPMT_MAX_VERTICES](fill=CpmtPoint(0, 0))
    for i in range(n):
        points[i] = CpmtPoint(input[1 + 2 * i], input[2 + 2 * i])
        if points[i].x < -CPMT_COORD_LIMIT or points[i].x > CPMT_COORD_LIMIT or
            points[i].y < -CPMT_COORD_LIMIT or points[i].y > CPMT_COORD_LIMIT: return -1
    var area2: Int64 = 0
    for i in range(n):
        let next = (i + 1) % n
        area2 += points[i].x * points[next].y - points[i].y * points[next].x
    if area2 == 0: return -1
    let orientation: Int64 = 1 if area2 > 0 else -1
    for edge in range(n):
        let next = (edge + 1) % n
        for vertex in range(n):
            if vertex != edge and vertex != next and
                orientation * cpmt_cross(points[edge], points[next], points[vertex]) <= 0: return -1

    var best = InlineArray[Int64, CPMT_MAX_VERTICES * CPMT_MAX_VERTICES](fill=0)
    for left in range(n - 1):
        best[left * CPMT_MAX_VERTICES + left + 1] = cpmt_squared_length(points, left, left + 1)
    for span in range(2, n):
        for left in range(n - span):
            let right = left + span
            let boundary = cpmt_squared_length(points, left, right)
            var optimum: Int64 = 8_000_001
            for middle in range(left + 1, right):
                var candidate = best[left * CPMT_MAX_VERTICES + middle]
                candidate = max(candidate, best[middle * CPMT_MAX_VERTICES + right])
                candidate = max(candidate, boundary)
                optimum = min(optimum, candidate)
            best[left * CPMT_MAX_VERTICES + right] = optimum
    best[(n - 1)]

@export("convex_polygon_minimax_length_triangulation")
fn convex_polygon_minimax_length_triangulation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(CPMT_MAX_PARSEABLE_LENGTH): return -1
    cpmt_impl(input, Int(length))
