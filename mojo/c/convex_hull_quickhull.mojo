from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn quick_hull_cross(points: InlineArray[Int64, 3072], a: Int64, b: Int64, c: Int64) -> Int64:
    return (points[3 * b] - points[3 * a]) * (points[3 * c + 1] - points[3 * a + 1]) - (points[3 * b + 1] - points[3 * a + 1]) * (points[3 * c] - points[3 * a])

@export("convex_hull_quickhull")
fn convex_hull_quickhull(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if length > 2048 or length % 2 != 0 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    let input_count = Int64(length / 2)
    var points = InlineArray[Int64, 3072](0)
    var order = InlineArray[Int64, 1024](0)
    for i in range(input_count):
        let x = values[2 * i]
        let y = values[2 * i + 1]
        if x < -1000000000 or x > 1000000000 or y < -1000000000 or y > 1000000000: return -1
        points[3 * i] = x
        points[3 * i + 1] = y
        points[3 * i + 2] = i
        order[i] = i
    if input_count == 0: return 0
    for i in range(1, input_count):
        let key = order[i]
        var j = i
        while j > 0:
            let prev = order[j - 1]
            let before = points[3 * key] < points[3 * prev] or (points[3 * key] == points[3 * prev] and (points[3 * key + 1] < points[3 * prev + 1] or (points[3 * key + 1] == points[3 * prev + 1] and points[3 * key + 2] < points[3 * prev + 2])) )
            if not before: break
            order[j] = prev
            j -= 1
        order[j] = key
    var unique_points = InlineArray[Int64, 3072](0)
    var count: Int64 = 0
    for i in range(input_count):
        let p = order[i]
        if count == 0 or unique_points[3 * (count - 1)] != points[3 * p] or unique_points[3 * (count - 1) + 1] != points[3 * p + 1]:
            for c in range(3): unique_points[3 * count + c] = points[3 * p + c]
            count += 1
    var on_hull = InlineArray[UInt8, 1024](0)
    if count == 1:
        on_hull[0] = 1
    else:
        on_hull[0] = 1
        on_hull[count - 1] = 1
        var stack_left = InlineArray[Int64, 4096](0)
        var stack_right = InlineArray[Int64, 4096](0)
        var top: Int64 = 0
        stack_left[top] = 0
        stack_right[top] = count - 1
        top += 1
        stack_left[top] = count - 1
        stack_right[top] = 0
        top += 1
        while top > 0:
            top -= 1
            let left = stack_left[top]
            let right = stack_right[top]
            var farthest: Int64 = -1
            var greatest: Int64 = 0
            for i in range(count):
                let area = quick_hull_cross(unique_points, left, right, i)
                if area > greatest:
                    greatest = area
                    farthest = i
            if farthest < 0: continue
            on_hull[farthest] = 1
            stack_left[top] = farthest
            stack_right[top] = right
            top += 1
            stack_left[top] = left
            stack_right[top] = farthest
            top += 1
    var hull_count: Int64 = 0
    for i in range(count):
        if on_hull[i] != 0: hull_count += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < 4 * hull_count: return -2
    var position: Int64 = 0
    for i in range(count):
        if on_hull[i] == 0: continue
        let id = UInt32(unique_points[3 * i + 2])
        for b in range(4): output[4 * position + b] = UInt8((id >> (8 * b)) & 255)
        position += 1
    return hull_count
