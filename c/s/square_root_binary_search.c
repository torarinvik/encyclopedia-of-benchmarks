#include <stdint.h>

/* Floor square root by binary search, with division avoiding square overflow. */
int64_t square_root_binary_search(int64_t value)
{
    if (value < 0) return -1;
    if (value < 2) return value;
    int64_t low = 1;
    int64_t high = value;
    int64_t answer = 0;
    while (low <= high) {
        const int64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            answer = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return answer;
}
