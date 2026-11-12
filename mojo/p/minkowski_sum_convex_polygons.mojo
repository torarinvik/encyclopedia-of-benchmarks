from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MS_MAX_VERTICES = 32
comptime MS_MAX_INPUT = 131
comptime MS_MAX_COORD: Int64 = 1_000_000

@fieldwise_init
struct MsPoint(Copyable):
    var x: Int64
    var y: Int64

fn ms_cross(a: MsPoint, b: MsPoint) -> Int64:
    a.x * b.y - a.y * b.x

fn ms_edge(p: InlineArray[MsPoint, MS_MAX_VERTICES], n: Int, i: Int) -> MsPoint:
    let next = (i + 1) % n
    MsPoint(p[next].x - p[i].x, p[next].y - p[i].y)

fn ms_half(v: MsPoint) -> Int:
    if v.y > 0 or (v.y == 0 and v.x >= 0): 0 else: 1

fn ms_angle_compare(a: MsPoint, b: MsPoint) -> Int:
    let ha = ms_half(a)
    let hb = ms_half(b)
    if ha != hb: return -1 if ha < hb else 1
    let turn = ms_cross(a, b)
    if turn > 0: return -1
    if turn < 0: return 1
    0

fn ms_valid_polygon(p: InlineArray[MsPoint, MS_MAX_VERTICES], n: Int) -> Bool:
    var wraps = 0
    for i in range(n):
        let a = ms_edge(p, n, i)
        let b = ms_edge(p, n, (i + 1) % n)
        if (a.x == 0 and a.y == 0) or ms_cross(a, b) <= 0: return False
        if ms_angle_compare(b, a) < 0: wraps += 1
    wraps == 1

fn ms_rotate_lowest(mut p: InlineArray[MsPoint, MS_MAX_VERTICES], n: Int):
    var first = 0
    for i in range(1, n):
        if p[i].y < p[first].y or (p[i].y == p[first].y and p[i].x < p[first].x): first = i
    var tmp = InlineArray[MsPoint, MS_MAX_VERTICES](fill=MsPoint(0, 0))
    for i in range(n): tmp[i] = p[(first + i) % n]
    for i in range(n): p[i] = tmp[i]

fn ms_put_i64(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): out[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("minkowski_sum_convex_polygons")
fn minkowski_sum_convex_polygons(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 14 or length > MS_MAX_INPUT: return -1
    if input[0] < 3 or input[0] > MS_MAX_VERTICES or input[1] < 3 or input[1] > MS_MAX_VERTICES: return -1
    let pn = Int(input[0]); let qn = Int(input[1]); let n = Int(length)
    if n != 2 + 2 * pn + 2 * qn: return -1
    var p = InlineArray[MsPoint, MS_MAX_VERTICES](fill=MsPoint(0, 0))
    var q = InlineArray[MsPoint, MS_MAX_VERTICES](fill=MsPoint(0, 0))
    var sums = InlineArray[MsPoint, 2 * MS_MAX_VERTICES](fill=MsPoint(0, 0))
    var at = 2
    for i in range(pn):
        p[i] = MsPoint(input[at], input[at + 1]); at += 2
        if p[i].x < -MS_MAX_COORD or p[i].x > MS_MAX_COORD or p[i].y < -MS_MAX_COORD or p[i].y > MS_MAX_COORD: return -1
    for i in range(qn):
        q[i] = MsPoint(input[at], input[at + 1]); at += 2
        if q[i].x < -MS_MAX_COORD or q[i].x > MS_MAX_COORD or q[i].y < -MS_MAX_COORD or q[i].y > MS_MAX_COORD: return -1
    if not ms_valid_polygon(p, pn) or not ms_valid_polygon(q, qn): return -1
    ms_rotate_lowest(mut p, pn); ms_rotate_lowest(mut q, qn)
    var i = 0; var j = 0; var count = 0
    while i < pn or j < qn:
        sums[count] = MsPoint(p[i % pn].x + q[j % qn].x, p[i % pn].y + q[j % qn].y)
        count += 1
        if i == pn: j += 1; continue
        if j == qn: i += 1; continue
        let order = ms_angle_compare(ms_edge(p, pn, i), ms_edge(q, qn, j))
        if order <= 0: i += 1
        if order >= 0: j += 1
    let needed = (1 + 2 * count) * 8
    if capacity < c_size_t(needed) or output == UnsafePointer[UInt8, MutAnyOrigin](): return -2
    ms_put_i64(output, 0, Int64(count))
    for k in range(count):
        ms_put_i64(output, 8 + 16 * k, sums[k].x)
        ms_put_i64(output, 16 + 16 * k, sums[k].y)
    Int64(needed)
