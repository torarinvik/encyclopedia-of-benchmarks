from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_POINTS = 64
comptime COORD_LIMIT = 1_000_000

struct Point:
    var x: Int64
    var y: Int64

    fn __init__(out self, x: Int64, y: Int64):
        self.x = x
        self.y = y

fn cross(a: Point, b: Point, c: Point) -> Int64:
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

fn before(a: Point, b: Point) -> Bool:
    return a.x < b.x or (a.x == b.x and a.y < b.y)

fn on_segment(point: Point, a: Point, b: Point) -> Bool:
    return cross(a, b, point) == 0 and min(a.x, b.x) <= point.x and point.x <= max(a.x, b.x) and
        min(a.y, b.y) <= point.y and point.y <= max(a.y, b.y)

@export("convex_layers")
fn convex_layers(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 1 + 2 * MAX_POINTS:
        return -1
    let raw_count = input[0]
    if raw_count < 0 or raw_count > Int64(MAX_POINTS): return -1
    let input_count = Int(raw_count)
    if length != c_size_t(1 + 2 * input_count): return -1

    var points = InlineArray[Point, MAX_POINTS](fill=Point(0, 0))
    var count = 0
    for index in range(input_count):
        let x = input[1 + 2 * index]
        let y = input[2 + 2 * index]
        if x < -Int64(COORD_LIMIT) or x > Int64(COORD_LIMIT) or
            y < -Int64(COORD_LIMIT) or y > Int64(COORD_LIMIT): return -1
        var duplicate = False
        for old in range(count):
            if points[old].x == x and points[old].y == y: duplicate = True
        if not duplicate:
            points[count] = Point(x, y)
            count += 1

    var layers: Int64 = 0
    while count > 0:
        for index in range(1, count):
            let key = points[index]
            var position = index
            while position > 0 and before(key, points[position - 1]):
                points[position] = points[position - 1]
                position -= 1
            points[position] = key

        var hull = InlineArray[Point, 2 * MAX_POINTS](fill=Point(0, 0))
        var hull_count = 0
        for index in range(count):
            while hull_count >= 2 and cross(hull[hull_count - 2], hull[hull_count - 1], points[index]) <= 0:
                hull_count -= 1
            hull[hull_count] = points[index]
            hull_count += 1
        let lower_count = hull_count
        for index in range(count - 1, 0, -1):
            let point = points[index - 1]
            while hull_count > lower_count and cross(hull[hull_count - 2], hull[hull_count - 1], point) <= 0:
                hull_count -= 1
            hull[hull_count] = point
            hull_count += 1
        if hull_count > 1: hull_count -= 1

        var boundary = InlineArray[Int, MAX_POINTS](fill=0)
        if hull_count <= 2:
            for index in range(count): boundary[index] = 1
        else:
            for index in range(count):
                for edge in range(hull_count):
                    if on_segment(points[index], hull[edge], hull[(edge + 1) % hull_count]):
                        boundary[index] = 1
                        break
        var remaining = InlineArray[Point, MAX_POINTS](fill=Point(0, 0))
        var kept = 0
        for index in range(count):
            if boundary[index] == 0:
                remaining[kept] = points[index]
                kept += 1
        if kept == count: return -1
        points = remaining
        count = kept
        layers += 1
    return layers
