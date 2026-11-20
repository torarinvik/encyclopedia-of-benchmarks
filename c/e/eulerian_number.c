/* Return A(n,k), the number of permutations with exactly k descents. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 20 };

int64_t eulerian_number(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return -1;
    const int64_t n = values[0], target = values[1];
    if (n < 0 || n > MAX_N || target < 0
            || (n == 0 ? target != 0 : target >= n)) return -1;

    int64_t previous[MAX_N + 1] = {0};
    int64_t current[MAX_N + 1] = {0};
    previous[0] = 1;
    for (int64_t row = 1; row <= n; ++row) {
        for (int64_t k = 0; k < row; ++k) {
            const int64_t same = previous[k];
            const int64_t fewer = k == 0 ? 0 : previous[k - 1];
            current[k] = (k + 1) * same + (row - k) * fewer;
        }
        for (size_t index = 0; index <= MAX_N; ++index) {
            previous[index] = current[index];
            current[index] = 0;
        }
    }
    return previous[target];
}
