from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn graham_cross(points: InlineArray[Int64, 192], a: Int64, b: Int64, c: Int64) -> Int64:
    let ax = points[2 * a]
    let ay = points[2 * a + 1]
    let bx = points[2 * b]
    let by = points[2 * b + 1]
    let cx = points[2 * c]
    let cy = points[2 * c + 1]
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

fn graham_orientation(points: InlineArray[Int64, 192], a: Int64, b: Int64, c: Int64) -> Int64:
    let turn = graham_cross(points, a, b, c)
    return 1 if turn < 0 else (-1 if turn > 0 else 0)

@export("convex_hull_graham")
fn convex_hull_graham(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length % 2 != 0 or length > 128: return -1
    let count = Int64(length / 2)
    if count < 3 or count > 64: return -1
    var points = InlineArray[Int64, 192](0)
    var order = InlineArray[Int64, 64](0)
    for i in range(count):
        let x = values[2 * i]
        let y = values[2 * i + 1]
        if x < -2000 or x > 2000 or y < -2000 or y > 2000: return -1
        points[2 * i] = x
        points[2 * i + 1] = y
        order[i] = i
    for i in range(1, count):
        let key = order[i]
        var j = i
        while j > 0 and points[2 * order[j - 1]] > points[2 * key]:
            order[j] = order[j - 1]
            j -= 1
        order[j] = key
    for i in range(1, count):
        if points[2 * order[i - 1]] == points[2 * order[i]]: return -1
    for i in range(1, count - 1):
        if graham_cross(points, order[0], order[i], order[count - 1]) == 0: return -1
    var upper = InlineArray[Int64, 64](0)
    var lower = InlineArray[Int64, 64](0)
    var upper_count: Int64 = 1
    var lower_count: Int64 = 1
    upper[0] = 0
    lower[0] = 0
    for i in range(1, count):
        let turn = graham_orientation(points, order[0], order[i], order[count - 1])
        if i == count - 1 or turn != -1:
            while upper_count >= 2 and graham_orientation(points, order[upper[upper_count - 2]], order[upper[upper_count - 1]], order[i]) == -1: upper_count -= 1
            upper[upper_count] = i
            upper_count += 1
        if i == count - 1 or turn != 1:
            while lower_count >= 2 and graham_orientation(points, order[lower[lower_count - 2]], order[lower[lower_count - 1]], order[i]) == 1: lower_count -= 1
            lower[lower_count] = i
            lower_count += 1
    let hull_count = upper_count - 2 + lower_count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 4 * hull_count: return -2
    var written: Int64 = 0
    for i in range(1, upper_count - 1):
        let id = UInt32(order[upper[i]])
        for b in range(4): output[4 * written + b] = UInt8((id >> (8 * b)) & 255)
        written += 1
    var i = lower_count
    while i > 0:
        i -= 1
        let id = UInt32(order[lower[i]])
        for b in range(4): output[4 * written + b] = UInt8((id >> (8 * b)) & 255)
        written += 1
    return hull_count
