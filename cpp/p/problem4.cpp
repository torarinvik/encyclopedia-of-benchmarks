#include <cstdint>

static bool is_palindrome(std::int64_t value) noexcept
{
    const std::int64_t original = value;
    std::int64_t reversed = 0;
    while (value > 0) {
        reversed = reversed * 10 + value % 10;
        value /= 10;
    }
    return reversed == original;
}

extern "C" std::int64_t problem4(std::int64_t digits) noexcept
{
    if (digits < 1 || digits > 3) return -1;
    const std::int64_t minimum = digits == 1 ? 1 : (digits == 2 ? 10 : 100);
    const std::int64_t maximum = digits == 1 ? 9 : (digits == 2 ? 99 : 999);
    std::int64_t largest = 0;
    for (std::int64_t first = maximum; first >= minimum && first * maximum > largest; --first) {
        for (std::int64_t second = maximum; second >= first && first * second > largest; --second) {
            const std::int64_t product = first * second;
            if (is_palindrome(product)) largest = product;
        }
    }
    return largest;
}
