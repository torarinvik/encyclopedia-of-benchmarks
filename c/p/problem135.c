/* Count values through limit with exactly ten valid arithmetic-progression solutions. */
#include <stdint.h>

#define MAX_LIMIT INT64_C(1000000)
#define FREQUENCY_SIZE 1000001

int64_t problem135(int64_t limit)
{
    if (limit > MAX_LIMIT) return -1;
    if (limit < 0) return 0;
    uint8_t frequency[FREQUENCY_SIZE] = {0};
    for (int64_t first_term = 1; first_term <= limit; ++first_term) {
        for (int64_t n = first_term; n <= limit; n += first_term) {
            int64_t common_difference = first_term + n / first_term;
            if (common_difference % 4 != 0) continue;
            common_difference /= 4;
            if (first_term > common_difference && first_term < 4 * common_difference &&
                frequency[n] < 11) ++frequency[n];
        }
    }
    int64_t count = 0;
    for (int64_t n = 1; n <= limit; ++n)
        if (frequency[n] == 10) ++count;
    return count;
}
