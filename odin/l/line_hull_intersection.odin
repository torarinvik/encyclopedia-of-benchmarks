package line_hull_intersection

import "core:c"

MAX_VERTICES :: 16
MAX_PARSEABLE_LENGTH :: 38
Point :: struct { x, y: i64 }
Vector :: struct { x, y: i64 }
Hit :: struct { edge, numerator, denominator: i64 }

polar_half :: proc "contextless" (v: Vector) -> int {
    if v.y > 0 || (v.y == 0 && v.x >= 0) do return 0
    return 1
}
angle_before :: proc "contextless" (a, b: Vector) -> bool {
    ah, bh := polar_half(a), polar_half(b)
    if ah != bh do return ah < bh
    return a.x * b.y - a.y * b.x > 0
}
rotation_minimum :: proc "contextless" (edges: []Vector) -> int {
    low, high := 0, len(edges) - 1
    for low < high {
        middle := (low + high) / 2
        if angle_before(edges[middle], edges[high]) { high = middle }
        else { low = middle + 1 }
    }
    return low
}
support_edge :: proc "contextless" (edges: []Vector, target: Vector) -> int {
    count := len(edges)
    pivot := rotation_minimum(edges)
    low, high := 0, count
    for low < high {
        middle := (low + high) / 2
        if angle_before(edges[(pivot + middle) % count], target) { low = middle + 1 }
        else { high = middle }
    }
    return (pivot + low) % count
}
line_value :: proc "contextless" (points: []Point, index: int, origin: Point, direction: Vector) -> i64 {
    return direction.x * (points[index].y - origin.y) - direction.y * (points[index].x - origin.x)
}
line_parameter :: proc "contextless" (point, origin: Point, direction: Vector) -> i64 {
    return (point.x - origin.x) * direction.x + (point.y - origin.y) * direction.y
}
crossing :: proc "contextless" (points: []Point, origin: Point, direction: Vector,
    start, finish: int, increasing: bool) -> Hit {
    count := len(points)
    span := (finish + count - start) % count
    low, high := 0, span
    for high - low > 1 {
        middle := (low + high) / 2
        value := line_value(points, (start + middle) % count, origin, direction)
        if (increasing && value < 0) || (!increasing && value > 0) { low = middle }
        else { high = middle }
    }
    index := (start + low) % count
    if line_value(points, (start + high) % count, origin, direction) == 0 {
        index = (start + high) % count
    }
    value := line_value(points, index, origin, direction)
    if value == 0 {
        return Hit{edge = i64(index), numerator = line_parameter(points[index], origin, direction), denominator = 1}
    }
    next := (index + 1) % count
    next_value := line_value(points, next, origin, direction)
    denominator := value - next_value
    edge_dot := (points[next].x - points[index].x) * direction.x +
                (points[next].y - points[index].y) * direction.y
    numerator := line_parameter(points[index], origin, direction) * denominator + value * edge_dot
    if denominator < 0 { numerator = -numerator; denominator = -denominator }
    return Hit{edge = i64(index), numerator = numerator, denominator = denominator}
}
store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export)
line_hull_intersection :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
    n_value := input[0]
    if n_value < 3 || n_value > MAX_VERTICES do return -1
    n := int(n_value)
    if length != c.size_t(5 + 2 * n) do return -1
    origin := Point{x = input[1], y = input[2]}
    line_end := Point{x = input[3], y = input[4]}
    if origin.x < -50 || origin.x > 50 || origin.y < -50 || origin.y > 50 ||
       line_end.x < -50 || line_end.x > 50 || line_end.y < -50 || line_end.y > 50 do return -1
    direction := Vector{x = line_end.x - origin.x, y = line_end.y - origin.y}
    if direction.x == 0 && direction.y == 0 do return -1

    points: [MAX_VERTICES]Point
    edges: [MAX_VERTICES]Vector
    for i := 0; i < n; i += 1 {
        points[i] = Point{x = input[5 + 2 * i], y = input[6 + 2 * i]}
        if points[i].x < -50 || points[i].x > 50 || points[i].y < -50 || points[i].y > 50 do return -1
        for j := 0; j < i; j += 1 {
            if points[j].x == points[i].x && points[j].y == points[i].y do return -1
        }
    }
    area2: i64 = 0
    for i := 0; i < n; i += 1 {
        next := (i + 1) % n
        edges[i] = Vector{x = points[next].x - points[i].x, y = points[next].y - points[i].y}
        area2 += points[i].x * points[next].y - points[next].x * points[i].y
    }
    if area2 <= 0 do return -1
    for i := 0; i < n; i += 1 {
        next := (i + 1) % n
        for j := 0; j < n; j += 1 {
            if j == i || j == next do continue
            side := edges[i].x * (points[j].y - points[i].y) - edges[i].y * (points[j].x - points[i].x)
            if side <= 0 do return -1
        }
    }

    maximum := support_edge(edges[:n], Vector{x = -direction.x, y = -direction.y})
    minimum := support_edge(edges[:n], direction)
    max_value := line_value(points[:n], maximum, origin, direction)
    min_value := line_value(points[:n], minimum, origin, direction)
    first, second: i64 = -1, -1
    if min_value > 0 || max_value < 0 {
        first, second = -1, -1
    } else if min_value == 0 || max_value == 0 {
        touch := minimum
        if min_value != 0 { touch = maximum }
        next, previous := (touch + 1) % n, (touch + n - 1) % n
        if line_value(points[:n], touch, origin, direction) == 0 && line_value(points[:n], next, origin, direction) == 0 {
            first, second = i64(touch), i64(touch)
        } else if line_value(points[:n], previous, origin, direction) == 0 && line_value(points[:n], touch, origin, direction) == 0 {
            first, second = i64(previous), i64(previous)
        } else {
            first, second = i64(touch), -1
        }
    } else {
        a := crossing(points[:n], origin, direction, maximum, minimum, false)
        b := crossing(points[:n], origin, direction, minimum, maximum, true)
        if a.numerator * b.denominator <= b.numerator * a.denominator { first, second = a.edge, b.edge }
        else { first, second = b.edge, a.edge }
    }
    if output == nil || capacity < 16 do return -2
    store_i64_le(output, 0, first)
    store_i64_le(output, 8, second)
    return 16
}
