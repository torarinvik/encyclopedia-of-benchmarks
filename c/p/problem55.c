#include <stddef.h>
#include <stdint.h>

#define MAX_LIMIT INT64_C(10000)
#define MAX_DIGITS 64

static size_t problem55_reverse_add(uint8_t *digits, size_t length)
{
    size_t reverse_length = length;
    while (reverse_length > 0 && digits[length - reverse_length] == 0) --reverse_length;
    const size_t combined_length = length > reverse_length ? length : reverse_length;
    uint8_t next[MAX_DIGITS] = {0};
    int carry = 0;
    for (size_t position = 0; position < combined_length; ++position) {
        const int left = position < length ? digits[position] : 0;
        const int right = position < reverse_length ? digits[length - 1 - position] : 0;
        const int sum = left + right + carry;
        next[position] = (uint8_t)(sum % 10);
        carry = sum / 10;
    }
    size_t next_length = combined_length;
    if (carry > 0) next[next_length++] = (uint8_t)carry;
    for (size_t index = 0; index < next_length; ++index) digits[index] = next[index];
    return next_length;
}

static int problem55_is_palindrome(const uint8_t *digits, size_t length)
{
    for (size_t left = 0; left < length / 2; ++left) {
        if (digits[left] != digits[length - 1 - left]) return 0;
    }
    return 1;
}

int64_t problem55(int64_t limit)
{
    if (limit < 0 || limit > MAX_LIMIT) return -1;
    int64_t count = 0;
    for (int64_t start = 1; start < limit; ++start) {
        uint8_t digits[MAX_DIGITS] = {0};
        size_t length = 0;
        uint64_t value = (uint64_t)start;
        while (value > 0) {
            digits[length++] = (uint8_t)(value % 10);
            value /= 10;
        }
        int became_palindrome = 0;
        for (int iteration = 0; iteration < 50; ++iteration) {
            length = problem55_reverse_add(digits, length);
            if (problem55_is_palindrome(digits, length)) {
                became_palindrome = 1;
                break;
            }
        }
        if (!became_palindrome) ++count;
    }
    return count;
}
