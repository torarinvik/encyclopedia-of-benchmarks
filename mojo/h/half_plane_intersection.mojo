from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime HPI_MAX_LINES = 16
comptime HPI_MAX_INPUT = 37
comptime HPI_BOX: Int64 = 256

@fieldwise_init
struct HpiLine(Copyable):
    var a: Int64
    var b: Int64
    var c: Int64

@fieldwise_init
struct HpiPoint(Copyable):
    var x: Int64
    var y: Int64
    var den: Int64

fn hpi_abs(x: Int64) -> Int64:
    if x < 0: -x else: x

fn hpi_gcd(a0: Int64, b0: Int64) -> Int64:
    var a = hpi_abs(a0)
    var b = hpi_abs(b0)
    while b != 0:
        let r = a % b
        a = b
        b = r
    a

fn hpi_half(h: HpiLine) -> Int:
    if h.b > 0 or (h.b == 0 and h.a >= 0): 0 else: 1

fn hpi_compare(x: HpiLine, y: HpiLine) -> Int:
    let hx = hpi_half(x)
    let hy = hpi_half(y)
    if hx != hy: return -1 if hx < hy else 1
    let turn = x.a * y.b - x.b * y.a
    if turn != 0: return -1 if turn > 0 else 1
    if x.c < y.c: return -1
    if x.c > y.c: return 1
    0

fn hpi_intersect(x: HpiLine, y: HpiLine) -> (Bool, HpiPoint):
    var det = x.a * y.b - y.a * x.b
    if det == 0: return (False, HpiPoint(0, 0, 1))
    var xn = x.c * y.b - x.b * y.c
    var yn = x.a * y.c - x.c * y.a
    if det < 0:
        det = -det
        xn = -xn
        yn = -yn
    let g = hpi_gcd(hpi_gcd(xn, yn), det)
    (True, HpiPoint(xn / g, yn / g, det / g))

fn hpi_outside(h: HpiLine, p: HpiPoint) -> Bool:
    h.a * p.x + h.b * p.y > h.c * p.den

fn hpi_same(x: HpiPoint, y: HpiPoint) -> Bool:
    x.x * y.den == y.x * x.den and x.y * y.den == y.y * x.den

fn hpi_orient(a: HpiPoint, b: HpiPoint, c: HpiPoint) -> Int64:
    let dx1 = b.x * a.den - a.x * b.den
    let dy1 = b.y * a.den - a.y * b.den
    let dx2 = c.x * b.den - b.x * c.den
    let dy2 = c.y * b.den - b.y * c.den
    dx1 * dy2 - dy1 * dx2

fn hpi_less_yx(a: HpiPoint, b: HpiPoint) -> Bool:
    let y1 = a.y * b.den
    let y2 = b.y * a.den
    if y1 != y2: y1 < y2 else: a.x * b.den < b.x * a.den

fn hpi_put_i64(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): out[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn hpi_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: Int, output_is_null: Bool) -> Int64:
    if length < 1 or length > HPI_MAX_INPUT: return -1
    if input[0] < 0 or input[0] > 12: return -1
    let count = Int(input[0])
    if length != 1 + 3 * count: return -1
    var lines = InlineArray[HpiLine, HPI_MAX_LINES](fill=HpiLine(0, 0, 0))
    var queue = InlineArray[HpiLine, HPI_MAX_LINES](fill=HpiLine(0, 0, 0))
    var points = InlineArray[HpiPoint, HPI_MAX_LINES](fill=HpiPoint(0, 0, 1))
    var clean = InlineArray[HpiPoint, HPI_MAX_LINES](fill=HpiPoint(0, 0, 1))
    var line_count = 0
    for i in range(count):
        let a = input[1 + 3 * i]
        let b = input[2 + 3 * i]
        let c = input[3 + 3 * i]
        if a < -16 or a > 16 or b < -16 or b > 16 or c < -128 or c > 128: return -1
        if (a == 0 and b == 0) or hpi_gcd(a, b) != 1: return -1
        lines[line_count] = HpiLine(a, b, c)
        line_count += 1
    lines[line_count] = HpiLine(1, 0, HPI_BOX); line_count += 1
    lines[line_count] = HpiLine(0, 1, HPI_BOX); line_count += 1
    lines[line_count] = HpiLine(-1, 0, HPI_BOX); line_count += 1
    lines[line_count] = HpiLine(0, -1, HPI_BOX); line_count += 1
    for i in range(1, line_count):
        let key = lines[i]
        var j = i
        while j > 0 and hpi_compare(key, lines[j - 1]) < 0:
            lines[j] = lines[j - 1]
            j -= 1
        lines[j] = key
    var reduced = 0
    for i in range(line_count):
        if reduced > 0 and lines[i].a == lines[reduced - 1].a and lines[i].b == lines[reduced - 1].b: continue
        lines[reduced] = lines[i]
        reduced += 1
    var head = 0
    var tail = 0
    var empty = False
    for i in range(reduced):
        let h = lines[i]
        while tail - head > 1:
            let (valid, p) = hpi_intersect(queue[tail - 2], queue[tail - 1])
            if not valid or not hpi_outside(h, p): break
            tail -= 1
        while tail - head > 1:
            let (valid, p) = hpi_intersect(queue[head], queue[head + 1])
            if not valid or not hpi_outside(h, p): break
            head += 1
        if tail > head:
            let last = queue[tail - 1]
            if last.a * h.b - last.b * h.a == 0:
                if last.a * h.a + last.b * h.b < 0:
                    head = 0
                    tail = 0
                    empty = True
                    break
                if h.c < last.c: queue[tail - 1] = h
                continue
        queue[tail] = h
        tail += 1
    if empty:
        head = 0
        tail = 0
    if tail - head >= 3:
        while tail - head > 2:
            let (valid, p) = hpi_intersect(queue[tail - 2], queue[tail - 1])
            if not valid or not hpi_outside(queue[head], p): break
            tail -= 1
        while tail - head > 2:
            let (valid, p) = hpi_intersect(queue[head], queue[head + 1])
            if not valid or not hpi_outside(queue[tail - 1], p): break
            head += 1
    var point_count = 0
    if tail - head >= 3:
        for i in range(head, tail):
            let next = if i + 1 == tail: head else: i + 1
            let (valid, p) = hpi_intersect(queue[i], queue[next])
            if not valid:
                point_count = 0
                break
            points[point_count] = p
            point_count += 1
    var clean_count = 0
    for i in range(point_count):
        if clean_count == 0 or not hpi_same(clean[clean_count - 1], points[i]):
            clean[clean_count] = points[i]
            clean_count += 1
    if clean_count > 1 and hpi_same(clean[0], clean[clean_count - 1]): clean_count -= 1
    var changed = True
    while changed and clean_count >= 3:
        changed = False
        for i in range(clean_count):
            let prev = (i + clean_count - 1) % clean_count
            let next = (i + 1) % clean_count
            if hpi_orient(clean[prev], clean[i], clean[next]) == 0:
                for j in range(i, clean_count - 1): clean[j] = clean[j + 1]
                clean_count -= 1
                changed = True
                break
    if clean_count < 3: clean_count = 0
    if clean_count > 0:
        var first = 0
        for i in range(1, clean_count):
            if hpi_less_yx(clean[i], clean[first]): first = i
        let old = clean
        for i in range(clean_count): clean[i] = old[(first + i) % clean_count]
    let needed = (1 + 4 * clean_count) * 8
    if output_is_null or needed > capacity: return -2
    hpi_put_i64(output, 0, Int64(clean_count))
    for i in range(clean_count):
        let gx = hpi_gcd(clean[i].x, clean[i].den)
        let gy = hpi_gcd(clean[i].y, clean[i].den)
        let base = 8 + 32 * i
        hpi_put_i64(output, base, clean[i].x / gx)
        hpi_put_i64(output, base + 8, clean[i].den / gx)
        hpi_put_i64(output, base + 16, clean[i].y / gy)
        hpi_put_i64(output, base + 24, clean[i].den / gy)
    Int64(needed)

@export("half_plane_intersection")
fn half_plane_intersection(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(HPI_MAX_INPUT): return -1
    let is_null = output == UnsafePointer[UInt8, MutAnyOrigin]()
    hpi_impl(input, Int(length), output, Int(capacity), is_null)
