/* Count integer partitions excluding the one-part representation. */
#include <cstdint>

namespace {
constexpr int MAX_TOTAL = 200;
constexpr int MAX_PARTS = 200;
constexpr int MEMO_SIZE = (MAX_TOTAL + 1) * MAX_PARTS;
}

extern "C" std::int64_t problem76(std::int64_t total) noexcept
{
    if (total < 1 || total > MAX_TOTAL) return -1;
    std::int64_t memo[MEMO_SIZE] = {};
    for (int n = 0; n <= total; ++n) memo[n * MAX_PARTS] = 1;
    for (int n = 0; n <= total; ++n) {
        for (int k = 1; k < total; ++k) {
            const int index = n * MAX_PARTS + k;
            memo[index] += memo[index - 1];
            if (n > k) memo[index] += memo[(n - k - 1) * MAX_PARTS + k];
        }
    }
    return memo[total * MAX_PARTS + total - 1] - 1;
}
