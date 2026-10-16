#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_LIMIT = 10'000;
constexpr std::size_t MAX_DIGITS = 64;

std::size_t reverse_add(std::uint8_t *digits, std::size_t length) noexcept
{
    std::size_t reverse_length = length;
    while (reverse_length > 0 && digits[length - reverse_length] == 0) --reverse_length;
    const std::size_t combined_length = std::max(length, reverse_length);
    std::uint8_t next[MAX_DIGITS]{};
    int carry = 0;
    for (std::size_t position = 0; position < combined_length; ++position) {
        const int left = position < length ? digits[position] : 0;
        const int right = position < reverse_length ? digits[length - 1 - position] : 0;
        const int sum = left + right + carry;
        next[position] = static_cast<std::uint8_t>(sum % 10);
        carry = sum / 10;
    }
    std::size_t next_length = combined_length;
    if (carry > 0) next[next_length++] = static_cast<std::uint8_t>(carry);
    for (std::size_t index = 0; index < next_length; ++index) digits[index] = next[index];
    return next_length;
}

bool is_palindrome(const std::uint8_t *digits, std::size_t length) noexcept
{
    for (std::size_t left = 0; left < length / 2; ++left) {
        if (digits[left] != digits[length - 1 - left]) return false;
    }
    return true;
}
}

extern "C" std::int64_t problem55(std::int64_t limit) noexcept
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    std::int64_t count = 0;
    for (std::int64_t start = 1; start < limit; ++start) {
        std::uint8_t digits[MAX_DIGITS]{};
        std::size_t length = 0;
        std::uint64_t value = static_cast<std::uint64_t>(start);
        while (value > 0) {
            digits[length++] = static_cast<std::uint8_t>(value % 10);
            value /= 10;
        }
        bool became_palindrome = false;
        for (int iteration = 0; iteration < 50; ++iteration) {
            length = reverse_add(digits, length);
            if (is_palindrome(digits, length)) {
                became_palindrome = true;
                break;
            }
        }
        if (!became_palindrome) ++count;
    }
    return count;
}
