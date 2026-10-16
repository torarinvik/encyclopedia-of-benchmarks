package problem174

MAX_TILES :: 1_000_000

ceil_sqrt :: proc(value: i64) -> i64 {
    if value <= 0 do return 0
    root := value
    next := (root + value / root) / 2
    for next < root {
        root = next
        next = (root + value / root) / 2
    }
    if root * root == value do return root
    return root + 1
}

@(export)
problem174 :: proc "c" (t_limit, n_limit: i64) -> i64 {
    if t_limit > MAX_TILES do return -1
    if t_limit < 0 do return 0
    count := make([]u8, int(t_limit) + 1)
    defer delete(count)
    outer_width := i64(3)
    for outer_width < t_limit / 4 + 2 {
        outer_area := outer_width * outer_width
        hole_lower := i64(1)
        if outer_area > t_limit {
            hole_lower = ceil_sqrt(outer_area - t_limit)
            if hole_lower < 1 { hole_lower = 1 }
        }
        if (outer_width - hole_lower) % 2 != 0 { hole_lower += 1 }
        for hole_width := hole_lower; hole_width < outer_width - 1; hole_width += 2 {
            tiles := outer_area - hole_width * hole_width
            count[int(tiles)] += 1
        }
        outer_width += 1
    }
    answer := i64(0)
    for tiles := 1; tiles <= int(t_limit); tiles += 1 {
        if count[tiles] >= 1 && i64(count[tiles]) <= n_limit { answer += 1 }
    }
    return answer
}
