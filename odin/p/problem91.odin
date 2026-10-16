// Count right triangles formed by unordered grid-point pairs and the origin.
package problem91

MAX_LIMIT :: i64(50)

@(export)
problem91 :: proc "c" (limit: i64) -> i64 {
    if limit < 0 || limit > MAX_LIMIT do return -1
    count: i64 = 0
    for x1 := i64(0); x1 <= limit; x1 += 1 {
        for y1 := i64(0); y1 <= limit; y1 += 1 {
            for x2 := x1; x2 <= limit; x2 += 1 {
                first_y2 := i64(0)
                if x2 == x1 { first_y2 = y1 + 1 }
                for y2 := first_y2; y2 <= limit; y2 += 1 {
                    if (x1 == 0 && y1 == 0) || (x2 == 0 && y2 == 0) { continue }
                    op := x1 * x1 + y1 * y1
                    oq := x2 * x2 + y2 * y2
                    dx := x1 - x2
                    dy := y1 - y2
                    pq := dx * dx + dy * dy
                    if op + oq == pq || op + pq == oq || oq + pq == op { count += 1 }
                }
            }
        }
    }
    return count
}
