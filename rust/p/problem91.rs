/// Count right triangles formed by unordered grid-point pairs and the origin.
const MAX_LIMIT: i64 = 50;

#[no_mangle]
pub extern "C" fn problem91(limit: i64) -> i64 {
    if limit < 0 || limit > MAX_LIMIT { return -1; }
    let mut count = 0i64;
    for x1 in 0..=limit {
        for y1 in 0..=limit {
            for x2 in x1..=limit {
                let first_y2 = if x2 == x1 { y1 + 1 } else { 0 };
                for y2 in first_y2..=limit {
                    if (x1 == 0 && y1 == 0) || (x2 == 0 && y2 == 0) { continue; }
                    let op = x1 * x1 + y1 * y1;
                    let oq = x2 * x2 + y2 * y2;
                    let dx = x1 - x2;
                    let dy = y1 - y2;
                    let pq = dx * dx + dy * dy;
                    if op + oq == pq || op + pq == oq || oq + pq == op { count += 1; }
                }
            }
        }
    }
    count
}
