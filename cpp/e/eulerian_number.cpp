// Return A(n,k), the number of permutations with exactly k descents.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t eulerian_number(const std::int64_t *values,
                                          std::size_t length) noexcept
{
    if (values == nullptr || length != 2) return -1;
    const std::int64_t n = values[0], target = values[1];
    if (n < 0 || n > 20 || target < 0
            || (n == 0 ? target != 0 : target >= n)) return -1;

    std::int64_t previous[21] = {};
    std::int64_t current[21] = {};
    previous[0] = 1;
    for (std::int64_t row = 1; row <= n; ++row) {
        for (std::int64_t k = 0; k < row; ++k) {
            const std::int64_t same = previous[k];
            const std::int64_t fewer = k == 0 ? 0 : previous[k - 1];
            current[k] = (k + 1) * same + (row - k) * fewer;
        }
        for (std::size_t index = 0; index < 21; ++index) {
            previous[index] = current[index];
            current[index] = 0;
        }
    }
    return previous[target];
}
