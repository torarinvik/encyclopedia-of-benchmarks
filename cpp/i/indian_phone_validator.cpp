#include <cstddef>
#include <cstdint>

static bool is_ascii_whitespace(std::int64_t value)
{
    return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32;
}

static bool mobile_tail(const std::int64_t *phone, std::size_t end, std::size_t position)
{
    if (position > end || end - position != 10) return false;
    if (phone[position] < '7' || phone[position] > '9') return false;
    for (std::size_t i = 1; i < 10; ++i) {
        if (phone[position + i] < '0' || phone[position + i] > '9') return false;
    }
    return true;
}

extern "C" std::int64_t indian_phone_validator(const std::int64_t *phone, std::size_t length)
{
    if (phone == nullptr || length == 0 || length > 18) return -1;
    for (std::size_t i = 0; i < length; ++i) {
        if (phone[i] < 0 || phone[i] > 127) return -1;
    }

    std::size_t end = length;
    if (phone[end - 1] == '\n') --end;
    std::size_t prefix = 0;
    if (end >= 3 && phone[0] == '+' && phone[1] == '9' && phone[2] == '1') {
        prefix = 3;
        if (prefix < end && (phone[prefix] == '-' || is_ascii_whitespace(phone[prefix]))) ++prefix;
    }

    for (int zero = 0; zero <= 1; ++zero) {
        std::size_t after_zero = prefix;
        if (zero == 1) {
            if (after_zero >= end || phone[after_zero] != '0') continue;
            ++after_zero;
        }
        for (int country = 0; country <= 1; ++country) {
            std::size_t position = after_zero;
            if (country == 1) {
                if (position + 2 > end || phone[position] != '9' || phone[position + 1] != '1') continue;
                position += 2;
            }
            if (mobile_tail(phone, end, position)) return 1;
        }
    }
    return 0;
}
