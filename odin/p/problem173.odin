package problem173

MAX_TILES :: i64(1_000_000)

problem173_ceil_sqrt :: proc(value: i64) -> i64 {
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
problem173 :: proc "c" (max_tiles: i64) -> i64 {
    if max_tiles < 0 || max_tiles > MAX_TILES do return -1
    answer := i64(0)
    outer_width := i64(3)
    for outer_width < max_tiles / 4 + 2 {
        hole_width := i64(1)
        outer_area := outer_width * outer_width
        if outer_area > max_tiles {
            hole_width = problem173_ceil_sqrt(outer_area - max_tiles)
            if hole_width < 1 { hole_width = 1 }
        }
        if (outer_width - hole_width) % 2 != 0 { hole_width += 1 }
        answer += (outer_width - hole_width - 2) / 2 + 1
        outer_width += 1
    }
    return answer
}
