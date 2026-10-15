// Can lowercase ASCII letters be rearranged into a palindrome?
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t can_string_be_rearranged_as_palindrome(const std::int64_t* text, std::size_t length) noexcept
{
    if (length == 0 || length > 4096) return -1;
    std::array<std::size_t, 26> counts{};
    std::size_t odd_count = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (text[index] < 'a' || text[index] > 'z') return -1;
        const auto letter = static_cast<std::size_t>(text[index] - 'a');
        if ((counts[letter] & 1U) == 0) ++odd_count;
        else --odd_count;
        ++counts[letter];
    }
    return odd_count <= 1 ? 1 : 0;
}
