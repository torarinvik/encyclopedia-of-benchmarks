package melkman_simple_polyline_hull

import "core:c"

Point :: struct { x, y: i64 }
turn :: proc(p: ^[32]Point, a, b, d: int) -> i64 {
    return (p[b].x-p[a].x)*(p[d].y-p[a].y) - (p[b].y-p[a].y)*(p[d].x-p[a].x)
}

@(export)
melkman_simple_polyline_hull :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 7 || length > 66 do return -1
    raw := input[0]
    if raw < 3 || raw > 32 do return -1
    n := int(raw)
    if length != c.size_t(1+2*n) do return -1
    points: [32]Point
    for i := 0; i < n; i += 1 {
        x, y := input[1+2*i], input[2+2*i]
        if x < -1000 || x > 1000 || y < -1000 || y > 1000 do return -1
        points[i] = Point{x, y}
    }
    initial := turn(&points, 0, 1, 2)
    if initial == 0 do return -1
    deque: [68]int
    first, last := 32, 35
    deque[32] = 2; deque[35] = 2
    if initial > 0 { deque[33] = 0; deque[34] = 1 } else { deque[33] = 1; deque[34] = 0 }
    for i := 3; i < n; i += 1 {
        if turn(&points, deque[first], deque[first+1], i) > 0 && turn(&points, deque[last-1], deque[last], i) > 0 do continue
        for last > first && turn(&points, deque[first], deque[first+1], i) <= 0 { first += 1 }
        if last <= first || first == 0 do return -1
        first -= 1; deque[first] = i
        for last > first && turn(&points, deque[last-1], deque[last], i) <= 0 { last -= 1 }
        if last <= first || last + 1 >= 68 do return -1
        last += 1; deque[last] = i
    }
    count := last-first
    start := 0
    for i := 1; i < count; i += 1 {
        a, b := points[deque[first+i]], points[deque[first+start]]
        if a.x < b.x || (a.x == b.x && a.y < b.y) { start = i }
    }
    bytes := 8*count
    if output == nil || capacity < c.size_t(bytes) do return -2
    staged: [256]u8
    for i := 0; i < count; i += 1 {
        index := u64(deque[first+(start+i)%count])
        for b := 0; b < 8; b += 1 { staged[8*i+b] = u8((index >> (8*b)) & 255) }
    }
    for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
    return i64(bytes)
}
