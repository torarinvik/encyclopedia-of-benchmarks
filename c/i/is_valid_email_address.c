#include <stddef.h>
#include <stdint.h>

static int ascii_letter(int64_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

static int ascii_digit(int64_t value)
{
    return value >= '0' && value <= '9';
}

static int local_special(int64_t value)
{
    switch (value) {
    case '!': case '#': case '$': case '%': case '&': case '\'': case '(': case ')':
    case '*': case '+': case '-': case '.': case '/': case '=': case '?': case '^':
    case '_': case '`': case '{': case '|': case '}': case '~':
        return 1;
    default:
        return 0;
    }
}

static int local_allowed(int64_t value)
{
    return ascii_letter(value) || ascii_digit(value) || local_special(value);
}

static int domain_allowed(int64_t value)
{
    return ascii_letter(value) || ascii_digit(value) || value == '.' || value == '-';
}

int64_t is_valid_email_address(const int64_t *values, size_t length)
{
    if (length > 320) return 0;
    if (length != 0 && values == NULL) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 0 || values[i] > 0x10ffff) return -1;
    }

    size_t at = length;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] == '@') {
            if (at != length) return 0;
            at = i;
        }
    }
    if (at == length) return 0;

    const size_t domain_start = at + 1;
    if (at > 64 || length - domain_start > 255) return 0;
    for (size_t i = 0; i < at; ++i) {
        const int64_t value = values[i];
        if (!local_allowed(value)) return 0;
        if (value == '.' && (i == 0 || i + 1 == at || values[i - 1] == '.')) return 0;
    }
    for (size_t i = domain_start; i < length; ++i) {
        const int64_t value = values[i];
        if (!domain_allowed(value)) return 0;
        if (value == '-' && i == domain_start) return 0;
        if (value == '.' && (i == domain_start || i + 1 == length || values[i - 1] == '.')) return 0;
    }
    return 1;
}
