package manhattan_mst

import "core:c"

MAX_POINTS :: 32
MAX_INPUT_LENGTH :: 1 + 2 * MAX_POINTS
COORDINATE_LIMIT :: i64(1_000_000)

@(export)
manhattan_mst :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
    count_value := values[0]
    if count_value < 1 || count_value > MAX_POINTS do return -1
    count := int(count_value)
    if length != c.size_t(1 + 2 * count) do return -1

    x: [MAX_POINTS]i64
    y: [MAX_POINTS]i64
    for point := 0; point < count; point += 1 {
        x[point] = values[1 + 2 * point]
        y[point] = values[2 + 2 * point]
        if x[point] < -COORDINATE_LIMIT || x[point] > COORDINATE_LIMIT ||
            y[point] < -COORDINATE_LIMIT || y[point] > COORDINATE_LIMIT do return -1
    }

    in_tree: [MAX_POINTS]bool
    has_best: [MAX_POINTS]bool
    best: [MAX_POINTS]i64
    for point := 0; point < MAX_POINTS; point += 1 {
        in_tree[point] = false
        has_best[point] = false
        best[point] = 0
    }
    has_best[0] = true
    total := i64(0)
    for _ := 0; _ < count; _ += 1 {
        selected := count
        for point := 0; point < count; point += 1 {
            if !in_tree[point] && has_best[point] &&
                (selected == count || best[point] < best[selected]) do selected = point
        }
        if selected == count do return -1
        in_tree[selected] = true
        total += best[selected]
        for point := 0; point < count; point += 1 {
            if in_tree[point] do continue
            dx := x[selected] - x[point]
            dy := y[selected] - y[point]
            if dx < 0 do dx = -dx
            if dy < 0 do dy = -dy
            distance := dx + dy
            if !has_best[point] || distance < best[point] {
                has_best[point] = true
                best[point] = distance
            }
        }
    }
    return total
}
