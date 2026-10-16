#include <cstddef>
#include <cstdint>

extern "C" std::int64_t validate_credit_card(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 1 || length > 65) return -1;
    const std::int64_t n = input[0];
    if (n < 0 || n > 64 || length != static_cast<std::size_t>(n) + 1) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;
    if (n < 13 || n > 16) return 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i)
        if (input[i + 1] < '0' || input[i + 1] > '9') return 0;
    const auto first = input[1] - '0';
    const auto second = input[2] - '0';
    if (!(first == 4 || first == 5 || first == 6 ||
          (first == 3 && (second == 4 || second == 5 || second == 7)))) return 0;
    int sum = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i) {
        int digit = static_cast<int>(input[i + 1] - '0');
        if (i % 2 == 0) { digit *= 2; if (digit > 9) digit -= 9; }
        sum += digit;
    }
    return sum % 10 == 0 ? 1 : 0;
}
