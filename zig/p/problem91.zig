/// Count right triangles formed by unordered grid-point pairs and the origin.
const MAX_LIMIT: i64 = 50;

export fn problem91(limit: i64) i64 {
    if (limit < 0 or limit > MAX_LIMIT) return -1;
    var count: i64 = 0;
    var x1: i64 = 0;
    while (x1 <= limit) : (x1 += 1) {
        var y1: i64 = 0;
        while (y1 <= limit) : (y1 += 1) {
            var x2 = x1;
            while (x2 <= limit) : (x2 += 1) {
                const first_y2: i64 = if (x2 == x1) y1 + 1 else 0;
                var y2 = first_y2;
                while (y2 <= limit) : (y2 += 1) {
                    if ((x1 == 0 and y1 == 0) or (x2 == 0 and y2 == 0)) continue;
                    const op = x1 * x1 + y1 * y1;
                    const oq = x2 * x2 + y2 * y2;
                    const dx = x1 - x2;
                    const dy = y1 - y2;
                    const pq = dx * dx + dy * dy;
                    if (op + oq == pq or op + pq == oq or oq + pq == op) count += 1;
                }
            }
        }
    }
    return count;
}
