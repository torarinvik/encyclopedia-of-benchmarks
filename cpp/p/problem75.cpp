#include <cstdint>
#include <vector>

static std::int64_t gcd_i64(std::int64_t left, std::int64_t right) noexcept
{
    while (right != 0) { const auto remainder = left % right; left = right; right = remainder; }
    return left;
}

extern "C" std::int64_t problem75(std::int64_t limit) noexcept
{
    if (limit > 1500000) return -1;
    if (limit < 0) return 0;
    std::vector<std::uint8_t> frequency(static_cast<std::size_t>(limit) + 1, 0);
    for (std::int64_t m = 2; 2 * m * (m + 1) <= limit; ++m) {
        for (std::int64_t n = (m % 2) + 1; n < m; n += 2) {
            if (gcd_i64(m, n) != 1) continue;
            const auto primitive_perimeter = 2 * m * (m + n);
            for (auto perimeter = primitive_perimeter; perimeter <= limit; perimeter += primitive_perimeter) {
                if (frequency[static_cast<std::size_t>(perimeter)] < 2) ++frequency[static_cast<std::size_t>(perimeter)];
            }
        }
    }
    std::int64_t unique = 0;
    for (std::int64_t perimeter = 1; perimeter <= limit; ++perimeter) unique += frequency[static_cast<std::size_t>(perimeter)] == 1;
    return unique;
}
