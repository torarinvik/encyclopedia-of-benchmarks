// Count right triangles formed by unordered grid-point pairs and the origin.
module problem91

const max_limit = i64(50)

@[export: 'problem91']
pub fn problem91(limit i64) i64 {
    if limit < 0 || limit > max_limit {
        return -1
    }
    mut count := i64(0)
    mut x1 := i64(0)
    for x1 <= limit {
        mut y1 := i64(0)
        for y1 <= limit {
            mut x2 := x1
            for x2 <= limit {
                first_y2 := i64(0)
                if x2 == x1 {
                    first_y2 = y1 + 1
                }
                mut y2 := first_y2
                for y2 <= limit {
                    if !((x1 == 0 && y1 == 0) || (x2 == 0 && y2 == 0)) {
                        op := x1 * x1 + y1 * y1
                        oq := x2 * x2 + y2 * y2
                        dx := x1 - x2
                        dy := y1 - y2
                        pq := dx * dx + dy * dy
                        if op + oq == pq || op + pq == oq || oq + pq == op {
                            count++
                        }
                    }
                    y2++
                }
                x2++
            }
            y1++
        }
        x1++
    }
    return count
}
