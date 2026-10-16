/* Count right triangles formed by unordered pairs of grid points and the origin. */
#include <stdint.h>

#define MAX_LIMIT INT64_C(50)

int64_t problem91(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    int64_t count = 0;
    for (int64_t x1 = 0; x1 <= limit; ++x1) {
        for (int64_t y1 = 0; y1 <= limit; ++y1) {
            for (int64_t x2 = x1; x2 <= limit; ++x2) {
                const int64_t first_y2 = x2 == x1 ? y1 + 1 : 0;
                for (int64_t y2 = first_y2; y2 <= limit; ++y2) {
                    if ((x1 == 0 && y1 == 0) || (x2 == 0 && y2 == 0)) continue;
                    const int64_t op = x1 * x1 + y1 * y1;
                    const int64_t oq = x2 * x2 + y2 * y2;
                    const int64_t pq = (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2);
                    if (op + oq == pq || op + pq == oq || oq + pq == op) ++count;
                }
            }
        }
    }
    return count;
}
