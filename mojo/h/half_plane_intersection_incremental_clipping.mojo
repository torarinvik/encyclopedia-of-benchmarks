# Independently authored draft; not compiled or run.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@fieldwise_init
struct ClipLine(Copyable):
    var a: Int64
    var b: Int64
    var c: Int64

@fieldwise_init
struct ClipVertex(Copyable):
    var x: Int64
    var y: Int64
    var den: Int64
    var incoming: Int

fn clip_abs(x: Int64) -> Int64:
    if x < 0: -x else: x

fn clip_gcd(a0: Int64, b0: Int64) -> Int64:
    var a = clip_abs(a0)
    var b = clip_abs(b0)
    while b != 0:
        let r = a % b
        a = b
        b = r
    a

fn clip_intersect(a: ClipLine, b: ClipLine) -> (Bool, ClipVertex):
    var d = a.a * b.b - b.a * a.b
    if d == 0: return (False, ClipVertex(0, 0, 1, 0))
    var x = a.c * b.b - a.b * b.c
    var y = a.a * b.c - a.c * b.a
    if d < 0:
        d = -d
        x = -x
        y = -y
    let g = clip_gcd(clip_gcd(x, y), d)
    (True, ClipVertex(x / g, y / g, d / g, 0))

fn clip_side(l: ClipLine, p: ClipVertex) -> Int64:
    l.a * p.x + l.b * p.y - l.c * p.den

fn clip_same(a: ClipVertex, b: ClipVertex) -> Bool:
    a.x * b.den == b.x * a.den and a.y * b.den == b.y * a.den

fn clip_turn(a: ClipVertex, b: ClipVertex, c: ClipVertex) -> Int64:
    let dx1 = b.x * a.den - a.x * b.den
    let dy1 = b.y * a.den - a.y * b.den
    let dx2 = c.x * b.den - b.x * c.den
    let dy2 = c.y * b.den - b.y * c.den
    dx1 * dy2 - dy1 * dx2

fn clip_put(out: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = UInt64(value)
    for byte in range(8): out[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

fn clip_impl(input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t, output_is_null: Bool) -> Int64:
    if length < 1 or length > 38: return -1
    if input[0] < 0 or input[0] > 12: return -1
    let n = Int(input[0])
    if length != 1 + 3 * n: return -1
    var lines = InlineArray[ClipLine, 16](fill=ClipLine(0, 0, 0))
    lines[0] = ClipLine(-1, 0, 256)
    lines[1] = ClipLine(0, -1, 256)
    lines[2] = ClipLine(1, 0, 256)
    lines[3] = ClipLine(0, 1, 256)
    for i in range(n):
        let a = input[1 + 3 * i]
        let b = input[2 + 3 * i]
        let c = input[3 + 3 * i]
        if a < -16 or a > 16 or b < -16 or b > 16 or c < -128 or c > 128: return -1
        if (a == 0 and b == 0) or clip_gcd(a, b) != 1: return -1
        lines[4 + i] = ClipLine(a, b, c)
    var polygon = InlineArray[ClipVertex, 32](fill=ClipVertex(0, 0, 1, 0))
    polygon[0] = ClipVertex(-256, -256, 1, 0)
    polygon[1] = ClipVertex(256, -256, 1, 1)
    polygon[2] = ClipVertex(256, 256, 1, 2)
    polygon[3] = ClipVertex(-256, 256, 1, 3)
    var count = 4
    for line in range(4, 4 + n):
        if count < 3: break
        var next = InlineArray[ClipVertex, 32](fill=ClipVertex(0, 0, 1, 0))
        var used = 0
        for i in range(count):
            let s = polygon[(i + count - 1) % count]
            let e = polygon[i]
            let s_in = clip_side(lines[line], s) <= 0
            let e_in = clip_side(lines[line], e) <= 0
            if s_in != e_in:
                let (valid, p0) = clip_intersect(lines[e.incoming], lines[line])
                if not valid: return -1
                var p = p0
                p.incoming = if s_in: e.incoming else: line
                if used == 0 or not clip_same(next[used - 1], p):
                    next[used] = p
                    used += 1
            if e_in and (used == 0 or not clip_same(next[used - 1], e)):
                next[used] = e
                used += 1
        if used > 1 and clip_same(next[0], next[used - 1]):
            next[0].incoming = next[used - 1].incoming
            used -= 1
        count = used
        for i in range(count): polygon[i] = next[i]
        var noncollinear = False
        if count >= 3:
            for i in range(count):
                if clip_turn(polygon[i], polygon[(i + 1) % count], polygon[(i + 2) % count]) != 0:
                    noncollinear = True
        if not noncollinear: count = 0
    var changed = True
    while changed and count >= 3:
        changed = False
        for i in range(count):
            if clip_turn(polygon[(i + count - 1) % count], polygon[i], polygon[(i + 1) % count]) == 0:
                for j in range(i, count - 1): polygon[j] = polygon[j + 1]
                count -= 1
                changed = True
                break
    if count < 3: count = 0
    var first = 0
    for i in range(1, count):
        let yi = polygon[i].y * polygon[first].den
        let yf = polygon[first].y * polygon[i].den
        if yi < yf or (yi == yf and polygon[i].x * polygon[first].den < polygon[first].x * polygon[i].den): first = i
    let needed = (1 + 4 * count) * 8
    if output_is_null or capacity < c_size_t(needed): return -2
    clip_put(output, 0, Int64(count))
    for i in range(count):
        let p = polygon[(first + i) % count]
        let gx = clip_gcd(p.x, p.den)
        let gy = clip_gcd(p.y, p.den)
        let base = 8 + 32 * i
        clip_put(output, base, p.x / gx)
        clip_put(output, base + 8, p.den / gx)
        clip_put(output, base + 16, p.y / gy)
        clip_put(output, base + 24, p.den / gy)
    Int64(needed)

@export("half_plane_intersection_incremental_clipping")
fn half_plane_intersection_incremental_clipping(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length > c_size_t(38): return -1
    let is_null = output == UnsafePointer[UInt8, MutAnyOrigin]()
    clip_impl(input, Int(length), output, capacity, is_null)
