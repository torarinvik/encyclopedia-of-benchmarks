/* ASCII alphanumeric palindrome check, ignoring case and punctuation. */
#include <stddef.h>
#include <stdint.h>

static int folded_alphanumeric(uint64_t value)
{
    return value - 48 <= 9 || value - 97 <= 25;
}

static int64_t mismatch_result(const int64_t *text, size_t left, size_t right)
{
    uint64_t bits = 0;
    for (size_t index = left; index < right; ++index) bits |= (uint64_t)text[index];
    return bits > 127 ? -1 : 0;
}

int64_t valid_palindrome(const int64_t *text, size_t length)
{
    if (length > 4096) return -1;
    if (length <= 1) return length == 1 && (uint64_t)text[0] > 127 ? -1 : 1;

    size_t left = 0;
    size_t right = length;
    while (left < right) {
        const uint64_t first = (uint64_t)text[left++] | 32;
        if (first > 127) return -1;
        if (!folded_alphanumeric(first)) continue;
        while (left < right) {
            const uint64_t last = (uint64_t)text[--right] | 32;
            if (last > 127) return -1;
            if (folded_alphanumeric(last)) {
                if (first != last) return mismatch_result(text, left, right);
                break;
            }
        }
    }
    return 1;
}
