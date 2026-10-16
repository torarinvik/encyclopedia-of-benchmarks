#include <stdint.h>
#include <stdlib.h>

#define MAX_LIMIT 1500000

static int64_t gcd_i64(int64_t left, int64_t right)
{
    while (right != 0) {
        int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

int64_t problem75(int64_t limit)
{
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    uint8_t *frequency = (uint8_t *)calloc((size_t)limit + 1, sizeof(uint8_t));
    if (frequency == NULL) return -1;
    for (int64_t m = 2; 2 * m * (m + 1) <= limit; ++m) {
        for (int64_t n = (m % 2) + 1; n < m; n += 2) {
            if (gcd_i64(m, n) != 1) continue;
            int64_t primitive_perimeter = 2 * m * (m + n);
            for (int64_t perimeter = primitive_perimeter; perimeter <= limit; perimeter += primitive_perimeter) {
                if (frequency[perimeter] < 2) ++frequency[perimeter];
            }
        }
    }
    int64_t unique = 0;
    for (int64_t perimeter = 1; perimeter <= limit; ++perimeter) unique += frequency[perimeter] == 1;
    free(frequency);
    return unique;
}
