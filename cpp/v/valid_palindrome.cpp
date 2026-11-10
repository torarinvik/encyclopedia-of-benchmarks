// ASCII alphanumeric palindrome check, ignoring case and punctuation.
#include <cstddef>
#include <cstdint>

namespace {

bool folded_alphanumeric(std::uint64_t value)
{
    return value - 48 <= 9 || value - 97 <= 25;
}

std::int64_t mismatch_result(const std::int64_t *text, std::size_t left, std::size_t right)
{
    std::uint64_t bits = 0;
    for (std::size_t index = left; index < right; ++index) bits |= static_cast<std::uint64_t>(text[index]);
    return bits > 127 ? -1 : 0;
}

}

extern "C" std::int64_t valid_palindrome(const std::int64_t *text, std::size_t length) noexcept {
    if (length > 4096) return -1;
    if (length <= 1) return length == 1 && static_cast<std::uint64_t>(text[0]) > 127 ? -1 : 1;

    std::size_t left = 0;
    std::size_t right = length;
    while (left < right) {
        const std::uint64_t first = static_cast<std::uint64_t>(text[left++]) | 32;
        if (first > 127) return -1;
        if (!folded_alphanumeric(first)) continue;
        while (left < right) {
            const std::uint64_t last = static_cast<std::uint64_t>(text[--right]) | 32;
            if (last > 127) return -1;
            if (folded_alphanumeric(last)) {
                if (first != last) return mismatch_result(text, left, right);
                break;
            }
        }
    }
    return 1;
}
