// Count right triangles formed by unordered grid-point pairs and the origin.
module problem91;

const long MAX_LIMIT = 50;

fn long problem91(long limit) @export("problem91") {
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    long count = 0;
    for (long x1 = 0; x1 <= limit; x1++) {
        for (long y1 = 0; y1 <= limit; y1++) {
            for (long x2 = x1; x2 <= limit; x2++) {
                long first_y2 = x2 == x1 ? y1 + 1 : 0;
                for (long y2 = first_y2; y2 <= limit; y2++) {
                    if ((x1 == 0 && y1 == 0) || (x2 == 0 && y2 == 0)) continue;
                    long op = x1 * x1 + y1 * y1;
                    long oq = x2 * x2 + y2 * y2;
                    long dx = x1 - x2;
                    long dy = y1 - y2;
                    long pq = dx * dx + dy * dy;
                    if (op + oq == pq || op + pq == oq || oq + pq == op) count++;
                }
            }
        }
    }
    return count;
}
