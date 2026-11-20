from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

const MAX_VERTICES = 16
const MAX_PARSEABLE_LENGTH = 38

struct Hit:
    var edge: Int64
    var numerator: Int64
    var denominator: Int64

fn polar_half(x: Int64, y: Int64) -> Int:
    return 0 if y > 0 or (y == 0 and x >= 0) else 1

fn angle_before(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> Bool:
    let ah = polar_half(ax, ay)
    let bh = polar_half(bx, by)
    if ah != bh:
        return ah < bh
    return ax * by - ay * bx > 0

fn rotation_minimum(ex: InlineArray[Int64, 16], ey: InlineArray[Int64, 16], count: Int) -> Int:
    var low = 0
    var high = count - 1
    while low < high:
        let middle = (low + high) // 2
        if angle_before(ex[middle], ey[middle], ex[high], ey[high]):
            high = middle
        else:
            low = middle + 1
    return low

fn support_edge(ex: InlineArray[Int64, 16], ey: InlineArray[Int64, 16], count: Int,
                tx: Int64, ty: Int64) -> Int:
    let pivot = rotation_minimum(ex, ey, count)
    var low = 0
    var high = count
    while low < high:
        let middle = (low + high) // 2
        let index = (pivot + middle) % count
        if angle_before(ex[index], ey[index], tx, ty):
            low = middle + 1
        else:
            high = middle
    return (pivot + low) % count

fn line_value(xs: InlineArray[Int64, 16], ys: InlineArray[Int64, 16], index: Int,
              ox: Int64, oy: Int64, dx: Int64, dy: Int64) -> Int64:
    return dx * (ys[index] - oy) - dy * (xs[index] - ox)

fn line_parameter(xs: InlineArray[Int64, 16], ys: InlineArray[Int64, 16], index: Int,
                   ox: Int64, oy: Int64, dx: Int64, dy: Int64) -> Int64:
    return (xs[index] - ox) * dx + (ys[index] - oy) * dy

fn crossing(xs: InlineArray[Int64, 16], ys: InlineArray[Int64, 16], count: Int,
            ox: Int64, oy: Int64, dx: Int64, dy: Int64,
            start: Int, end: Int, increasing: Bool) -> Hit:
    let span = (end + count - start) % count
    var low = 0
    var high = span
    while high - low > 1:
        let middle = (low + high) // 2
        let value = line_value(xs, ys, (start + middle) % count, ox, oy, dx, dy)
        if (increasing and value < 0) or ((not increasing) and value > 0):
            low = middle
        else:
            high = middle
    var index = (start + low) % count
    if line_value(xs, ys, (start + high) % count, ox, oy, dx, dy) == 0:
        index = (start + high) % count
    let value = line_value(xs, ys, index, ox, oy, dx, dy)
    if value == 0:
        return Hit(edge=Int64(index), numerator=line_parameter(xs, ys, index, ox, oy, dx, dy), denominator=1)
    let next = (index + 1) % count
    let next_value = line_value(xs, ys, next, ox, oy, dx, dy)
    var denominator = value - next_value
    let edge_dot = (xs[next] - xs[index]) * dx + (ys[next] - ys[index]) * dy
    var numerator = line_parameter(xs, ys, index, ox, oy, dx, dy) * denominator + value * edge_dot
    if denominator < 0:
        numerator = -numerator
        denominator = -denominator
    return Hit(edge=Int64(index), numerator=numerator, denominator=denominator)

fn store_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    var bits = value.bitcast[UInt64]()
    for byte in range(8):
        output[offset + byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8

@export("line_hull_intersection")
fn line_hull_intersection(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > MAX_PARSEABLE_LENGTH:
        return -1
    let count_value = input[0]
    if count_value < 3 or count_value > MAX_VERTICES:
        return -1
    let count = Int(count_value)
    if length != c_size_t(5 + 2 * count):
        return -1
    let ox, oy, x2, y2 = input[1], input[2], input[3], input[4]
    if ox < -50 or ox > 50 or oy < -50 or oy > 50 or x2 < -50 or x2 > 50 or y2 < -50 or y2 > 50:
        return -1
    let dx = x2 - ox
    let dy = y2 - oy
    if dx == 0 and dy == 0:
        return -1

    var xs = InlineArray[Int64, 16]()
    var ys = InlineArray[Int64, 16]()
    var ex = InlineArray[Int64, 16]()
    var ey = InlineArray[Int64, 16]()
    for i in range(count):
        xs[i] = input[5 + 2 * i]
        ys[i] = input[6 + 2 * i]
        if xs[i] < -50 or xs[i] > 50 or ys[i] < -50 or ys[i] > 50:
            return -1
        for j in range(i):
            if xs[j] == xs[i] and ys[j] == ys[i]:
                return -1
    var area2: Int64 = 0
    for i in range(count):
        let next = (i + 1) % count
        ex[i] = xs[next] - xs[i]
        ey[i] = ys[next] - ys[i]
        area2 += xs[i] * ys[next] - xs[next] * ys[i]
    if area2 <= 0:
        return -1
    for i in range(count):
        let next = (i + 1) % count
        for j in range(count):
            if j == i or j == next:
                continue
            let side = ex[i] * (ys[j] - ys[i]) - ey[i] * (xs[j] - xs[i])
            if side <= 0:
                return -1

    let maximum = support_edge(ex, ey, count, -dx, -dy)
    let minimum = support_edge(ex, ey, count, dx, dy)
    let max_value = line_value(xs, ys, maximum, ox, oy, dx, dy)
    let min_value = line_value(xs, ys, minimum, ox, oy, dx, dy)
    var first: Int64 = -1
    var second: Int64 = -1
    if min_value > 0 or max_value < 0:
        first = -1
        second = -1
    elif min_value == 0 or max_value == 0:
        let touch = minimum if min_value == 0 else maximum
        let next = (touch + 1) % count
        let previous = (touch + count - 1) % count
        if line_value(xs, ys, touch, ox, oy, dx, dy) == 0 and line_value(xs, ys, next, ox, oy, dx, dy) == 0:
            first = Int64(touch)
            second = Int64(touch)
        elif line_value(xs, ys, previous, ox, oy, dx, dy) == 0 and line_value(xs, ys, touch, ox, oy, dx, dy) == 0:
            first = Int64(previous)
            second = Int64(previous)
        else:
            first = Int64(touch)
            second = -1
    else:
        let a = crossing(xs, ys, count, ox, oy, dx, dy, maximum, minimum, False)
        let b = crossing(xs, ys, count, ox, oy, dx, dy, minimum, maximum, True)
        if a.numerator * b.denominator <= b.numerator * a.denominator:
            first = a.edge
            second = b.edge
        else:
            first = b.edge
            second = a.edge
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16:
        return -2
    store_i64_le(output, 0, first)
    store_i64_le(output, 8, second)
    return 16
