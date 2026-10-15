// Smallest base in which a nonnegative integer is palindromic.
#include <cstdint>

static bool is_palindromic_in_base(std::int64_t number, std::int64_t base)
{
    if (number <= 1) return true;
    if (number % base == 0) return false;
    std::int64_t remaining = number;
    std::int64_t reversed = 0;
    while (remaining > 0) {
        reversed = reversed * base + remaining % base;
        remaining /= base;
    }
    return reversed == number;
}

extern "C" std::int64_t lowest_base_palindrome(std::int64_t number)
{
    if (number < 0 || number > 64) return -1;
    std::int64_t base = 2;
    while (!is_palindromic_in_base(number, base)) ++base;
    return base;
}
