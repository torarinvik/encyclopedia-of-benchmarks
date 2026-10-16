#include <cstdint>

static std::int64_t count_reversible(std::int64_t remaining, std::int64_t carry, int* digits, std::int64_t length)
{
    if (remaining == 0) {
        if (digits[0] == 0 || digits[length - 1] == 0) return 0;
        for (std::int64_t i = length / 2 - 1; i >= 0; --i) {
            carry += digits[i] + digits[length - i - 1];
            if (carry % 2 == 0) return 0;
            carry /= 10;
        }
        return 1;
    }
    if (remaining == 1) {
        if (carry % 2 == 0) return 0;
        std::int64_t result = 0;
        for (int digit = 0; digit < 10; ++digit) {
            digits[length / 2] = digit;
            result += count_reversible(0, (carry + 2 * digit) / 10, digits, length);
        }
        return result;
    }
    std::int64_t result = 0;
    const auto right_index = (length + remaining) / 2 - 1;
    const auto left_index = (length - remaining) / 2;
    for (int digit1 = 0; digit1 < 10; ++digit1) {
        digits[right_index] = digit1;
        const int parity = (carry + digit1) % 2 == 0 ? 1 : 0;
        for (int digit2 = parity; digit2 < 10; digit2 += 2) {
            digits[left_index] = digit2;
            result += count_reversible(remaining - 2, (carry + digit1 + digit2) / 10, digits, length);
        }
    }
    return result;
}

extern "C" std::int64_t problem145(std::int64_t max_power) noexcept
{
    if (max_power > 9) return -1;
    if (max_power <= 0) return 0;
    int digits[9]{};
    std::int64_t total = 0;
    for (std::int64_t length = 1; length <= max_power; ++length) {
        if ((length - 1) % 4 == 0) continue;
        total += count_reversible(length, 0, digits, length);
    }
    return total;
}
