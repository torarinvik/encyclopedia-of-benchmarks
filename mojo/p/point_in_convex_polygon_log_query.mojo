from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime PCL_MAX_VERTICES = 32
comptime PCL_MAX_QUERIES = 32
comptime PCL_MAX_INPUT = 131
comptime PCL_MAX_COORD: Int64 = 1_000_000

@fieldwise_init
struct PclPoint(Copyable):
    var x: Int64
    var y: Int64

fn pcl_sub(a: PclPoint, b: PclPoint) -> PclPoint:
    PclPoint(a.x - b.x, a.y - b.y)

fn pcl_cross(a: PclPoint, b: PclPoint) -> Int64:
    a.x * b.y - a.y * b.x

fn pcl_on_segment(a: PclPoint, b: PclPoint, p: PclPoint) -> Bool:
    let edge = pcl_sub(b, a)
    let rel = pcl_sub(p, a)
    pcl_cross(edge, rel) == 0 and p.x >= min(a.x, b.x) and p.x <= max(a.x, b.x)
        and p.y >= min(a.y, b.y) and p.y <= max(a.y, b.y)

fn pcl_valid_polygon(p: InlineArray[PclPoint, PCL_MAX_VERTICES], n: Int) -> Bool:
    for i in range(n):
        let next = (i + 1) % n
        if p[i].x == p[next].x and p[i].y == p[next].y: return False
        let edge = pcl_sub(p[next], p[i])
        for j in range(n):
            if j != i and j != next and pcl_cross(edge, pcl_sub(p[j], p[i])) <= 0: return False
        for j in range(i + 1, n):
            if p[i].x == p[j].x and p[i].y == p[j].y: return False
    True

fn pcl_contains(fan: InlineArray[PclPoint, PCL_MAX_VERTICES], m: Int, query: PclPoint) -> Int64:
    let origin = PclPoint(0, 0)
    let first = pcl_cross(fan[0], query)
    let last = pcl_cross(fan[m - 1], query)
    if first < 0 or last > 0: return 0
    if first == 0: return 1 if pcl_on_segment(origin, fan[0], query) else 0
    if last == 0: return 1 if pcl_on_segment(origin, fan[m - 1], query) else 0
    var lo = 0
    var hi = m
    while hi - lo > 1:
        let mid = (lo + hi) // 2
        if pcl_cross(fan[mid], query) >= 0: lo = mid else: hi = mid
    let side = pcl_cross(pcl_sub(fan[lo + 1], fan[lo]), pcl_sub(query, fan[lo]))
    if side < 0: return 0
    if side == 0: return 1 if pcl_on_segment(fan[lo], fan[lo + 1], query) else 0
    1

fn pcl_put_i64(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): out[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn pcl_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: Int, output_is_null: Bool) -> Int64:
    if length < 2 or length > PCL_MAX_INPUT: return -1
    if input[0] < 3 or input[0] > PCL_MAX_VERTICES or input[1] < 0 or input[1] > PCL_MAX_QUERIES: return -1
    let vertices = Int(input[0])
    let queries = Int(input[1])
    if length != 2 + 2 * vertices + 2 * queries: return -1
    var polygon = InlineArray[PclPoint, PCL_MAX_VERTICES](fill=PclPoint(0, 0))
    var fan = InlineArray[PclPoint, PCL_MAX_VERTICES](fill=PclPoint(0, 0))
    var query_points = InlineArray[PclPoint, PCL_MAX_QUERIES](fill=PclPoint(0, 0))
    var answers = InlineArray[Int64, PCL_MAX_QUERIES](fill=0)
    var at = 2
    for i in range(vertices):
        polygon[i] = PclPoint(input[at], input[at + 1]); at += 2
        if polygon[i].x < -PCL_MAX_COORD or polygon[i].x > PCL_MAX_COORD or polygon[i].y < -PCL_MAX_COORD or polygon[i].y > PCL_MAX_COORD: return -1
    if not pcl_valid_polygon(polygon, vertices): return -1
    for i in range(queries):
        query_points[i] = PclPoint(input[at], input[at + 1]); at += 2
        if query_points[i].x < -PCL_MAX_COORD or query_points[i].x > PCL_MAX_COORD or query_points[i].y < -PCL_MAX_COORD or query_points[i].y > PCL_MAX_COORD: return -1
    var pivot = 0
    for i in range(1, vertices):
        if polygon[i].x < polygon[pivot].x or (polygon[i].x == polygon[pivot].x and polygon[i].y < polygon[pivot].y): pivot = i
    for i in range(vertices - 1): fan[i] = pcl_sub(polygon[(pivot + i + 1) % vertices], polygon[pivot])
    for i in range(queries): answers[i] = pcl_contains(fan, vertices - 1, pcl_sub(query_points[i], polygon[pivot]))
    let needed = 8 * queries
    if needed > capacity or (output_is_null and needed > 0): return -2
    for i in range(queries): pcl_put_i64(output, 8 * i, answers[i])
    Int64(needed)

@export("point_in_convex_polygon_log_query")
fn point_in_convex_polygon_log_query(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(PCL_MAX_INPUT): return -1
    let is_null = output == UnsafePointer[UInt8, MutAnyOrigin]()
    pcl_impl(input, Int(length), output, Int(capacity), is_null)
