#include <stddef.h>
#include <stdint.h>

static int is_ascii_whitespace(int64_t value)
{
    return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32;
}

static int mobile_tail(const int64_t *phone, size_t end, size_t position)
{
    if (position > end || end - position != 10) return 0;
    if (phone[position] < '7' || phone[position] > '9') return 0;
    for (size_t i = 1; i < 10; ++i) {
        if (phone[position + i] < '0' || phone[position + i] > '9') return 0;
    }
    return 1;
}

int64_t indian_phone_validator(const int64_t *phone, size_t length)
{
    if (phone == NULL || length == 0 || length > 18) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (phone[i] < 0 || phone[i] > 127) return -1;
    }

    size_t end = length;
    if (phone[end - 1] == '\n') --end; /* Python's $ accepts before one final LF. */

    size_t prefix = 0;
    if (end >= 3 && phone[0] == '+' && phone[1] == '9' && phone[2] == '1') {
        prefix = 3;
        if (prefix < end && (phone[prefix] == '-' || is_ascii_whitespace(phone[prefix]))) ++prefix;
    }

    /* Optional groups can backtrack in the source regex; try each valid parse. */
    for (int zero = 0; zero <= 1; ++zero) {
        size_t after_zero = prefix;
        if (zero) {
            if (after_zero >= end || phone[after_zero] != '0') continue;
            ++after_zero;
        }
        for (int country = 0; country <= 1; ++country) {
            size_t position = after_zero;
            if (country) {
                if (position + 2 > end || phone[position] != '9' || phone[position + 1] != '1') continue;
                position += 2;
            }
            if (mobile_tail(phone, end, position)) return 1;
        }
    }
    return 0;
}
