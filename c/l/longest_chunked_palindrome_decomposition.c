/* Count chunks by greedily peeling the shortest matching prefix and suffix. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t longest_chunked_palindrome_decomposition(const int64_t *text, size_t length)
{
    if (length > 128) return -1;
    for (size_t index = 0; index < length; ++index)
        if (text[index] < 1 || text[index] > 127) return -1;
    size_t left = 0, right = length;
    int64_t chunks = 0;
    while (left < right) {
        const size_t remaining = right - left;
        bool matched = false;
        for (size_t size = 1; size <= remaining / 2 && !matched; ++size) {
            bool equal = true;
            for (size_t offset = 0; offset < size; ++offset)
                if (text[left + offset] != text[right - size + offset]) { equal = false; break; }
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
