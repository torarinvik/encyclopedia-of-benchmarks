from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime EPT_MAX_VERTICES = 32
comptime EPT_MAX_QUERIES = 16
comptime EPT_MAX_INPUT = 99
comptime EPT_MAX_COORDINATE: Int64 = 1000

@fieldwise_init
struct EptPoint(Copyable):
    var x: Int64
    var y: Int64

fn ept_sub(a: EptPoint, b: EptPoint) -> EptPoint:
    EptPoint(a.x - b.x, a.y - b.y)

fn ept_cross(a: EptPoint, b: EptPoint) -> Int64:
    a.x * b.y - a.y * b.x

fn ept_valid_polygon(p: InlineArray[EptPoint, EPT_MAX_VERTICES], n: Int) -> Bool:
    for i in range(n):
        let next = (i + 1) % n
        if p[i].x == p[next].x and p[i].y == p[next].y: return False
        let edge = ept_sub(p[next], p[i])
        for j in range(n):
            if j != i and j != next and ept_cross(edge, ept_sub(p[j], p[i])) <= 0: return False
    True

fn ept_valid_query(p: InlineArray[EptPoint, EPT_MAX_VERTICES], n: Int, q: EptPoint) -> Bool:
    var outside = False
    for i in range(n):
        let side = ept_cross(ept_sub(p[(i + 1) % n], p[i]), ept_sub(q, p[i]))
        if side == 0: return False
        if side < 0: outside = True
    outside

fn ept_build_chain(mut chain: InlineArray[Int, EPT_MAX_VERTICES], n: Int, start: Int, stop: Int) -> Int:
    var length = 0
    var at = start
    while True:
        if length >= n: return 0
        chain[length] = at
        length += 1
        if at == stop: return length
        at = (at + 1) % n

fn ept_build_layers(p: InlineArray[EptPoint, EPT_MAX_VERTICES], n: Int,
                    mut lower: InlineArray[Int, EPT_MAX_VERTICES],
                    mut upper: InlineArray[Int, EPT_MAX_VERTICES]) -> (Int, Int):
    var min_x = 0
    var max_x = 0
    for i in range(1, n):
        if p[i].x < p[min_x].x: min_x = i
        if p[i].x > p[max_x].x: max_x = i
    var left_bottom = min_x
    var left_top = min_x
    var right_bottom = max_x
    var right_top = max_x
    for i in range(n):
        if p[i].x == p[min_x].x:
            if p[i].y < p[left_bottom].y: left_bottom = i
            if p[i].y > p[left_top].y: left_top = i
        if p[i].x == p[max_x].x:
            if p[i].y < p[right_bottom].y: right_bottom = i
            if p[i].y > p[right_top].y: right_top = i
    let lower_len = ept_build_chain(lower, n, left_bottom, right_bottom)
    let upper_len = ept_build_chain(upper, n, right_top, left_top)
    (lower_len, upper_len)

fn ept_split_ascending(p: InlineArray[EptPoint, EPT_MAX_VERTICES],
                       chain: InlineArray[Int, EPT_MAX_VERTICES], length: Int, qx: Int64) -> Int:
    var lo = 0
    var hi = length
    while lo < hi:
        let mid = lo + (hi - lo) // 2
        if p[chain[mid]].x < qx: lo = mid + 1 else: hi = mid
    if lo == 0: 0 else: lo - 1

fn ept_split_descending(p: InlineArray[EptPoint, EPT_MAX_VERTICES],
                        chain: InlineArray[Int, EPT_MAX_VERTICES], length: Int, qx: Int64) -> Int:
    var lo = 0
    var hi = length
    while lo < hi:
        let mid = lo + (hi - lo) // 2
        if p[chain[mid]].x > qx: lo = mid + 1 else: hi = mid
    if lo == 0: 0 else: lo - 1

fn ept_tangent_search(p: InlineArray[EptPoint, EPT_MAX_VERTICES], n: Int,
                      chain: InlineArray[Int, EPT_MAX_VERTICES], first: Int, last: Int,
                      q: EptPoint, sign: Int64) -> Int:
    var lo = first
    var hi = last
    var result = lo
    while lo <= hi:
        let mid = lo + (hi - lo) // 2
        let index = chain[mid]
        let here = ept_sub(p[index], q)
        let to_next = sign * ept_cross(here, ept_sub(p[(index + 1) % n], q))
        let to_prev = sign * ept_cross(here, ept_sub(p[(index + n - 1) % n], q))
        if to_next >= 0 and to_prev >= 0: return mid
        if to_next >= 0:
            result = mid
            hi = mid - 1
        else:
            lo = mid + 1
    result

fn ept_supports(p: InlineArray[EptPoint, EPT_MAX_VERTICES], n: Int,
                index: Int, q: EptPoint, sign: Int64) -> Bool:
    let here = ept_sub(p[index], q)
    sign * ept_cross(here, ept_sub(p[(index + n - 1) % n], q)) > 0 and
        sign * ept_cross(here, ept_sub(p[(index + 1) % n], q)) > 0

fn ept_find_tangents(p: InlineArray[EptPoint, EPT_MAX_VERTICES], n: Int,
                     lower: InlineArray[Int, EPT_MAX_VERTICES], lower_len: Int,
                     upper: InlineArray[Int, EPT_MAX_VERTICES], upper_len: Int,
                     q: EptPoint) -> (Int, Int, Bool):
    if lower_len == 0 or upper_len == 0: return (-1, -1, False)
    let lower_split = ept_split_ascending(p, lower, lower_len, q.x)
    let upper_split = ept_split_descending(p, upper, upper_len, q.x)
    let left_a = lower[ept_tangent_search(p, n, lower, 0, lower_split, q, -1)]
    let left_b = upper[ept_tangent_search(p, n, upper, 0, upper_split, q, -1)]
    let right_a = lower[ept_tangent_search(p, n, lower, lower_split, lower_len - 1, q, 1)]
    let right_b = upper[ept_tangent_search(p, n, upper, upper_split, upper_len - 1, q, 1)]
    var left = -1
    var right = -1
    if ept_supports(p, n, left_a, q, -1): left = left_a
    elif ept_supports(p, n, left_b, q, -1): left = left_b
    if ept_supports(p, n, right_a, q, 1): right = right_a
    elif ept_supports(p, n, right_b, q, 1): right = right_b
    if left < 0 or right < 0 or left == right: return (-1, -1, False)
    if left < right: return (left, right, True)
    (right, left, True)

fn ept_put_i64(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): out[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn ept_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int,
            output: UnsafePointer[UInt8, MutAnyOrigin], capacity: Int, output_is_null: Bool) -> Int64:
    if length < 2 or length > EPT_MAX_INPUT: return -1
    if input[0] < 3 or input[0] > EPT_MAX_VERTICES or input[1] < 0 or input[1] > EPT_MAX_QUERIES: return -1
    let n = Int(input[0])
    let q_count = Int(input[1])
    if length != 2 + 2 * n + 2 * q_count: return -1
    var polygon = InlineArray[EptPoint, EPT_MAX_VERTICES](fill=EptPoint(0, 0))
    var query_points = InlineArray[EptPoint, EPT_MAX_QUERIES](fill=EptPoint(0, 0))
    var answers = InlineArray[Int64, 2 * EPT_MAX_QUERIES](fill=0)
    var at = 2
    for i in range(n):
        polygon[i] = EptPoint(input[at], input[at + 1]); at += 2
        if polygon[i].x < -EPT_MAX_COORDINATE or polygon[i].x > EPT_MAX_COORDINATE or
            polygon[i].y < -EPT_MAX_COORDINATE or polygon[i].y > EPT_MAX_COORDINATE: return -1
    if not ept_valid_polygon(polygon, n): return -1
    var lower = InlineArray[Int, EPT_MAX_VERTICES](fill=0)
    var upper = InlineArray[Int, EPT_MAX_VERTICES](fill=0)
    let (lower_len, upper_len) = ept_build_layers(polygon, n, mut lower, mut upper)
    if lower_len == 0 or upper_len == 0: return -1
    for i in range(q_count):
        query_points[i] = EptPoint(input[at], input[at + 1]); at += 2
        if query_points[i].x < -EPT_MAX_COORDINATE or query_points[i].x > EPT_MAX_COORDINATE or
            query_points[i].y < -EPT_MAX_COORDINATE or query_points[i].y > EPT_MAX_COORDINATE or
            not ept_valid_query(polygon, n, query_points[i]): return -1
        let (first, second, ok) = ept_find_tangents(polygon, n, lower, lower_len,
                                                     upper, upper_len, query_points[i])
        if not ok: return -1
        answers[2 * i] = Int64(first)
        answers[2 * i + 1] = Int64(second)
    let needed = 16 * q_count
    if needed > capacity or output_is_null: return -2
    for i in range(2 * q_count): ept_put_i64(output, 8 * i, answers[i])
    Int64(needed)

@export("external_point_tangents_convex_polygon")
fn external_point_tangents_convex_polygon(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(EPT_MAX_INPUT): return -1
    let output_is_null = output == UnsafePointer[UInt8, MutAnyOrigin]()
    ept_impl(input, Int(length), output, Int(capacity), output_is_null)
