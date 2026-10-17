#include <cstddef>
#include <cstdint>

namespace {
bool is_palindromic(std::uint32_t value)
{
    std::uint32_t reversed = 0, remaining = value;
    while (remaining > 0) {
        reversed = 10 * reversed + remaining % 10;
        remaining /= 10;
    }
    return reversed == value;
}
}

extern "C" std::int64_t euler_problem_4(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > 2 || input[0] < 1 || input[0] > 3 || length != 1) return -1;
    std::uint32_t lower = 1;
    for (int digit = 1; digit < static_cast<int>(input[0]); ++digit) lower *= 10;
    const std::uint32_t upper = lower * 10 - 1;
    std::uint32_t maximum = 0;
    for (std::uint32_t left = lower; left <= upper; ++left) {
        for (std::uint32_t right = lower; right <= upper; ++right) {
            const std::uint32_t product = left * right;
            if (product > maximum && is_palindromic(product)) maximum = product;
        }
    }
    return static_cast<std::int64_t>(maximum);
}
