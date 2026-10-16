/* Count integer partitions excluding the one-part representation. */
#include <stdint.h>

enum { MAX_TOTAL = 200, MAX_PARTS = 200, MEMO_SIZE = (MAX_TOTAL + 1) * MAX_PARTS };

int64_t problem76(int64_t total)
{
    if (total < 1 || total > MAX_TOTAL) return -1;
    int64_t memo[MEMO_SIZE] = {0};
    for (int64_t n = 0; n <= total; ++n) memo[n * MAX_PARTS] = 1;
    for (int64_t n = 0; n <= total; ++n) {
        for (int64_t k = 1; k < total; ++k) {
            const int64_t index = n * MAX_PARTS + k;
            memo[index] += memo[index - 1];
            if (n > k) memo[index] += memo[(n - k - 1) * MAX_PARTS + k];
        }
    }
    return memo[total * MAX_PARTS + total - 1] - 1;
}
