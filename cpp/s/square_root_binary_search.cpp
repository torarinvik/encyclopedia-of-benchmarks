#include <cstdint>

/* Floor square root by binary search, with division avoiding square overflow. */
extern "C" std::int64_t square_root_binary_search(std::int64_t value)
{
    if (value < 0) return -1;
    if (value < 2) return value;
    std::int64_t low = 1;
    std::int64_t high = value;
    std::int64_t answer = 0;
    while (low <= high) {
        const std::int64_t middle = low + (high - low) / 2;
        if (middle <= value / middle) {
            answer = middle;
            low = middle + 1;
        } else {
            high = middle - 1;
        }
    }
    return answer;
}
