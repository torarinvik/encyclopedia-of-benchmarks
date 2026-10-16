module problem174

const max_tiles = i64(1000000)

fn ceil_sqrt(value i64) i64 {
    if value <= 0 { return 0 }
    mut root := value
    mut next := (root + value / root) / 2
    for next < root {
        root = next
        next = (root + value / root) / 2
    }
    return if root * root == value { root } else { root + 1 }
}

@[export: 'problem174']
pub fn problem174(t_limit i64, n_limit i64) i64 {
    if t_limit > max_tiles { return -1 }
    if t_limit < 0 { return 0 }
    mut count := []u8{len: int(t_limit) + 1, init: 0}
    mut outer_width := i64(3)
    for outer_width < t_limit / 4 + 2 {
        outer_area := outer_width * outer_width
        mut hole_lower := i64(1)
        if outer_area > t_limit {
            hole_lower = ceil_sqrt(outer_area - t_limit)
            if hole_lower < 1 { hole_lower = 1 }
        }
        if (outer_width - hole_lower) % 2 != 0 { hole_lower++ }
        mut hole_width := hole_lower
        for hole_width < outer_width - 1 {
            tiles := int(outer_area - hole_width * hole_width)
            count[tiles]++
            hole_width += 2
        }
        outer_width++
    }
    mut answer := i64(0)
    for tiles in 1 .. int(t_limit) + 1 {
        if count[tiles] >= 1 && i64(count[tiles]) <= n_limit { answer++ }
    }
    return answer
}
