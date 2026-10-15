/* Count chunks by greedily peeling the shortest matching prefix and suffix. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t longest_chunked_palindrome_decomposition(
    const std::int64_t *text, std::size_t length) noexcept
{
    if (length > 128) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (text[index] < 1 || text[index] > 127) return -1;
    std::size_t left = 0, right = length;
    std::int64_t chunks = 0;
    while (left < right) {
        const auto remaining = right - left;
        bool matched = false;
        for (std::size_t size = 1; size <= remaining / 2 && !matched; ++size) {
            bool equal = true;
            for (std::size_t offset = 0; offset < size; ++offset) {
                if (text[left + offset] != text[right - size + offset]) { equal = false; break; }
            }
            if (equal) {
                chunks += 2;
                left += size;
                right -= size;
                matched = true;
            }
        }
        if (!matched) return chunks + 1;
    }
    return chunks;
}
