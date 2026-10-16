/* Validate an ASCII credit card string using prefix, length, and Luhn checks. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t credit_card_validator(const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::size_t max_text_length = 64;
    if (input == nullptr || length < 1 || length > max_text_length + 1) return -1;
    const auto n = input[0];
    if (n < 0 || n > static_cast<std::int64_t>(max_text_length) || length != static_cast<std::size_t>(n) + 1) return -1;
    bool digits = true;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i) {
        const auto ch = input[i + 1];
        if (ch < 0 || ch > 127) return -1;
        if (ch < '0' || ch > '9') digits = false;
    }
    if (!digits || n < 13 || n > 16) return 0;
    const auto first = input[1] - '0';
    const auto second = n >= 2 ? input[2] - '0' : -1;
    if (!(first == 4 || first == 5 || first == 6 || (first == 3 && (second == 4 || second == 5 || second == 7)))) return 0;
    int sum = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i) {
        int digit = static_cast<int>(input[i + 1] - '0');
        if (static_cast<std::int64_t>(i % 2) == n % 2) { digit *= 2; if (digit > 9) digit -= 9; }
        sum += digit;
    }
    return sum % 10 == 0 ? 1 : 0;
}
