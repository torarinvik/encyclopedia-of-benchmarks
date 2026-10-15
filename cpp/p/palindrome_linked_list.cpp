/* Compare the linked-list value sequence from both ends without mutation. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t palindrome_linked_list(const std::int64_t *values,
                                                std::size_t length) noexcept
{
    if (length > 100000) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 9) return -1;
    }

    std::size_t left = 0;
    std::size_t right = length;
    while (left < right) {
        --right;
        if (values[left] != values[right]) return 0;
        ++left;
    }
    return 1;
}
