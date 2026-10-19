from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn graham_scan_cross(points: InlineArray[Int64, 3072], a: Int64, b: Int64, c: Int64) -> Int64:
    let ax = points[3 * a]
    let ay = points[3 * a + 1]
    let bx = points[3 * b]
    let by = points[3 * b + 1]
    let cx = points[3 * c]
    let cy = points[3 * c + 1]
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

fn graham_scan_xy_before(points: InlineArray[Int64, 3072], a: Int64, b: Int64) -> Bool:
    if points[3 * a] != points[3 * b]: return points[3 * a] < points[3 * b]
    if points[3 * a + 1] != points[3 * b + 1]: return points[3 * a + 1] < points[3 * b + 1]
    return points[3 * a + 2] < points[3 * b + 2]

fn graham_scan_angle_before(points: InlineArray[Int64, 3072], a: Int64, b: Int64, pivot: Int64) -> Bool:
    let turn = graham_scan_cross(points, pivot, a, b)
    if turn != 0: return turn > 0
    let ax = points[3 * a] - points[3 * pivot]
    let ay = points[3 * a + 1] - points[3 * pivot + 1]
    let bx = points[3 * b] - points[3 * pivot]
    let by = points[3 * b + 1] - points[3 * pivot + 1]
    let ra = ax * ax + ay * ay
    let rb = bx * bx + by * by
    if ra != rb: return ra < rb
    return points[3 * a + 2] < points[3 * b + 2]

@export("convex_hull_graham_scan")
fn convex_hull_graham_scan(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if length > 2048 or length % 2 != 0 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    let input_count = Int64(length / 2)
    var original = InlineArray[Int64, 3072](0)
    var order = InlineArray[Int64, 1024](0)
    for i in range(input_count):
        let x = values[2 * i]
        let y = values[2 * i + 1]
        if x < -1000000000 or x > 1000000000 or y < -1000000000 or y > 1000000000: return -1
        original[3 * i] = x
        original[3 * i + 1] = y
        original[3 * i + 2] = i
        order[i] = i
    if input_count == 0: return 0
    for i in range(1, input_count):
        let key = order[i]
        var j = i
        while j > 0 and graham_scan_xy_before(original, key, order[j - 1]):
            order[j] = order[j - 1]
            j -= 1
        order[j] = key
    var points = InlineArray[Int64, 3072](0)
    var unique_count: Int64 = 0
    for i in range(input_count):
        let candidate = order[i]
        if unique_count == 0 or points[3 * (unique_count - 1)] != original[3 * candidate] or points[3 * (unique_count - 1) + 1] != original[3 * candidate + 1]:
            for c in range(3): points[3 * unique_count + c] = original[3 * candidate + c]
            unique_count += 1
    if unique_count == 1:
        if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < 4: return -2
        let id = UInt32(points[2])
        for b in range(4): output[b] = UInt8((id >> (8 * b)) & 255)
        return 1
    var pivot: Int64 = 0
    for i in range(1, unique_count):
        if points[3 * i + 1] < points[3 * pivot + 1] or (points[3 * i + 1] == points[3 * pivot + 1] and points[3 * i] < points[3 * pivot]): pivot = i
        order[i] = i
    order[0] = 0
    for i in range(1, unique_count):
        let key = order[i]
        var j = i
        while j > 0 and graham_scan_angle_before(points, key, order[j - 1], pivot):
            order[j] = order[j - 1]
            j -= 1
        order[j] = key
    var all_collinear = True
    for i in range(2, unique_count):
        if graham_scan_cross(points, pivot, order[1], order[i]) != 0:
            all_collinear = False
            break
    if not all_collinear:
        var final_begin = unique_count - 1
        while final_begin > 1 and graham_scan_cross(points, pivot, order[final_begin - 1], order[unique_count - 1]) == 0: final_begin -= 1
        var left = final_begin
        var right = unique_count - 1
        while left < right:
            let temp = order[left]
            order[left] = order[right]
            order[right] = temp
            left += 1
            right -= 1
    var hull = InlineArray[Int64, 1024](0)
    var hull_count: Int64 = 0
    for i in range(unique_count):
        let point = order[i]
        while hull_count >= 2 and graham_scan_cross(points, hull[hull_count - 2], hull[hull_count - 1], point) < 0: hull_count -= 1
        hull[hull_count] = point
        hull_count += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < 4 * hull_count: return -2
    for i in range(hull_count):
        let id = UInt32(points[3 * hull[i] + 2])
        for b in range(4): output[4 * i + b] = UInt8((id >> (8 * b)) & 255)
    return hull_count
