from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

struct ClosestPair:
    var valid: Bool
    var distance_squared: UInt64
    var first: Int64
    var second: Int64

fn closest_before(left: Int64, right: Int64, points: UnsafePointer[Int64, ImmutAnyOrigin], by_y: Bool) -> Bool:
    if by_y:
        if points[2 * left + 1] != points[2 * right + 1]: return points[2 * left + 1] < points[2 * right + 1]
        if points[2 * left] != points[2 * right]: return points[2 * left] < points[2 * right]
    else:
        if points[2 * left] != points[2 * right]: return points[2 * left] < points[2 * right]
        if points[2 * left + 1] != points[2 * right + 1]: return points[2 * left + 1] < points[2 * right + 1]
    return left < right

fn closest_distance(first: Int64, second: Int64, points: UnsafePointer[Int64, ImmutAnyOrigin]) -> UInt64:
    let dx = points[2 * first] - points[2 * second]
    let dy = points[2 * first + 1] - points[2 * second + 1]
    return UInt64(dx * dx) + UInt64(dy * dy)

fn closest_choose(left: ClosestPair, right: ClosestPair) -> ClosestPair:
    if not left.valid: return right
    if not right.valid: return left
    if left.distance_squared < right.distance_squared: return left
    if right.distance_squared < left.distance_squared: return right
    if left.first < right.first or (left.first == right.first and left.second <= right.second): return left
    return right

fn closest_candidate(a: Int64, b: Int64, points: UnsafePointer[Int64, ImmutAnyOrigin]) -> ClosestPair:
    let first = a if a < b else b
    let second = b if a < b else a
    return ClosestPair(True, closest_distance(first, second, points), first, second)

fn closest_sort(indices: InlineArray[Int64, 1024], count: Int64, points: UnsafePointer[Int64, ImmutAnyOrigin], by_y: Bool) -> InlineArray[Int64, 1024]:
    var sorted = indices
    for i in range(1, count):
        let key = sorted[i]
        var pos = i
        while pos > 0 and closest_before(key, sorted[pos - 1], points, by_y):
            sorted[pos] = sorted[pos - 1]
            pos -= 1
        sorted[pos] = key
    return sorted

fn closest_search(x_order: InlineArray[Int64, 1024], begin: Int64, end: Int64, y_order: InlineArray[Int64, 1024], y_count: Int64, rank: InlineArray[Int64, 1024], points: UnsafePointer[Int64, ImmutAnyOrigin]) -> ClosestPair:
    let count = end - begin
    if count <= 3:
        var best = ClosestPair(False, 0, 0, 0)
        for i in range(begin, end):
            for j in range(i + 1, end):
                best = closest_choose(best, closest_candidate(x_order[i], x_order[j], points))
        return best
    let middle = begin + count / 2
    var y_left = InlineArray[Int64, 1024](0)
    var y_right = InlineArray[Int64, 1024](0)
    var left_count: Int64 = 0
    var right_count: Int64 = 0
    for i in range(y_count):
        let point = y_order[i]
        if rank[point] < middle:
            y_left[left_count] = point
            left_count += 1
        else:
            y_right[right_count] = point
            right_count += 1
    let left = closest_search(x_order, begin, middle, y_left, left_count, rank, points)
    let right = closest_search(x_order, middle, end, y_right, right_count, rank, points)
    var best = closest_choose(left, right)
    var strip = InlineArray[Int64, 1024](0)
    var strip_count: Int64 = 0
    let middle_x = points[2 * x_order[middle]]
    for i in range(y_count):
        let point = y_order[i]
        let dx = points[2 * point] - middle_x
        if UInt64(dx * dx) <= best.distance_squared:
            strip[strip_count] = point
            strip_count += 1
    for i in range(strip_count):
        for j in range(i + 1, strip_count):
            let dy = points[2 * strip[j] + 1] - points[2 * strip[i] + 1]
            if UInt64(dy * dy) > best.distance_squared: break
            best = closest_choose(best, closest_candidate(strip[i], strip[j], points))
    return best

@export("closest_pair_divide_and_conquer")
fn closest_pair_divide_and_conquer(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if length > 2048 or length % 2 != 0 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    let count = Int64(length / 2)
    var x_order = InlineArray[Int64, 1024](0)
    var y_order = InlineArray[Int64, 1024](0)
    var rank = InlineArray[Int64, 1024](0)
    for i in range(count):
        if values[2 * i] < -1000000000 or values[2 * i] > 1000000000 or values[2 * i + 1] < -1000000000 or values[2 * i + 1] > 1000000000: return -1
        x_order[i] = i
        y_order[i] = i
    if count < 2: return 0
    x_order = closest_sort(x_order, count, values, False)
    for i in range(count): rank[x_order[i]] = i
    y_order = closest_sort(y_order, count, values, True)
    let best = closest_search(x_order, 0, count, y_order, count, rank, values)
    if not best.valid: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    for b in range(4):
        output[b] = UInt8((UInt32(best.first) >> (8 * b)) & 255)
        output[4 + b] = UInt8((UInt32(best.second) >> (8 * b)) & 255)
    return 2
