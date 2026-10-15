#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 100000;

bool is_palindrome_range(const std::int64_t *text, std::size_t left, std::size_t right)
{
    while (left < right) {
        if (text[left] != text[right - 1]) return false;
        ++left;
        --right;
    }
    return true;
}
}

extern "C" std::int64_t almost_palindrome_checker(const std::int64_t *text,
                                                    std::size_t length) noexcept
{
    if (length > MAX_LENGTH) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (text[index] < 'a' || text[index] > 'z') return -1;
    std::size_t left = 0;
    std::size_t right = length;
    while (left < right) {
        if (text[left] != text[right - 1])
            return is_palindrome_range(text, left + 1, right) ||
                   is_palindrome_range(text, left, right - 1);
        ++left;
        --right;
    }
    return 1;
}
