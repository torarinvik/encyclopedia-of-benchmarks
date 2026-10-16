#include <cstddef>
#include <cstdint>

namespace {
bool ascii_letter(std::int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}
bool ascii_digit(std::int64_t value) { return value >= '0' && value <= '9'; }
bool local_special(std::int64_t value) {
    switch (value) {
    case '!': case '#': case '$': case '%': case '&': case '\'': case '(': case ')':
    case '*': case '+': case '-': case '.': case '/': case '=': case '?': case '^':
    case '_': case '`': case '{': case '|': case '}': case '~': return true;
    default: return false;
    }
}
bool local_allowed(std::int64_t value) { return ascii_letter(value) || ascii_digit(value) || local_special(value); }
bool domain_allowed(std::int64_t value) { return ascii_letter(value) || ascii_digit(value) || value == '.' || value == '-'; }
}

extern "C" std::int64_t is_valid_email_address(const std::int64_t *values, std::size_t length) {
    if (length > 320) return 0;
    if (length != 0 && values == nullptr) return -1;
    for (std::size_t i = 0; i < length; ++i) if (values[i] < 0 || values[i] > 0x10ffff) return -1;
    std::size_t at = length;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] == '@') { if (at != length) return 0; at = i; }
    }
    if (at == length) return 0;
    const std::size_t domain_start = at + 1;
    if (at > 64 || length - domain_start > 255) return 0;
    for (std::size_t i = 0; i < at; ++i) {
        const auto value = values[i];
        if (!local_allowed(value)) return 0;
        if (value == '.' && (i == 0 || i + 1 == at || values[i - 1] == '.')) return 0;
    }
    for (std::size_t i = domain_start; i < length; ++i) {
        const auto value = values[i];
        if (!domain_allowed(value)) return 0;
        if (value == '-' && i == domain_start) return 0;
        if (value == '.' && (i == domain_start || i + 1 == length || values[i - 1] == '.')) return 0;
    }
    return 1;
}
