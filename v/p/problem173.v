module problem173

const max_tiles_limit = i64(1000000)

fn problem173_ceil_sqrt(value i64) i64 {
    if value <= 0 { return 0 }
    mut root := value
    mut next := (root + value / root) / 2
    for next < root {
        root = next
        next = (root + value / root) / 2
    }
    if root * root == value { return root }
    return root + 1
}

@[export: 'problem173']
pub fn problem173(max_tiles i64) i64 {
    if max_tiles < 0 || max_tiles > max_tiles_limit { return -1 }
    mut answer := i64(0)
    mut outer_width := i64(3)
    for outer_width < max_tiles / 4 + 2 {
        mut hole_width := i64(1)
        outer_area := outer_width * outer_width
        if outer_area > max_tiles {
            hole_width = problem173_ceil_sqrt(outer_area - max_tiles)
            if hole_width < 1 { hole_width = 1 }
        }
        if (outer_width - hole_width) % 2 != 0 { hole_width++ }
        answer += (outer_width - hole_width - 2) / 2 + 1
        outer_width++
    }
    return answer
}
