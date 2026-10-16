#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_N = 256;
constexpr std::size_t MAX_OUTPUT = 527;
std::size_t write_i64(std::uint8_t *out, std::size_t pos, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) out[pos++] = static_cast<std::uint8_t>(bits >> (8 * i));
    return pos;
}
}

extern "C" std::int64_t min_palindromic_insert(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > MAX_N + 1) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MAX_N) || length != static_cast<std::size_t>(n_value + 1)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    std::uint8_t chars[MAX_N];
    for (std::size_t i = 0; i < n; ++i) { if (input[i + 1] < 32 || input[i + 1] > 126) return -1; chars[i] = static_cast<std::uint8_t>(input[i + 1]); }
    std::uint16_t dp[MAX_N][MAX_N]{};
    for (std::size_t span = 2; span <= n; ++span) for (std::size_t left = 0; left + span <= n; ++left) {
        const auto right = left + span - 1;
        if (chars[left] == chars[right]) dp[left][right] = span > 2 ? dp[left + 1][right - 1] : 0;
        else dp[left][right] = static_cast<std::uint16_t>((dp[left + 1][right] < dp[left][right - 1] ? dp[left + 1][right] : dp[left][right - 1]) + 1);
    }
    const std::size_t insertions = dp[0][n - 1], out_length = n + insertions;
    std::uint8_t palindrome[2 * MAX_N - 1];
    std::size_t left = 0, right = n - 1, out_left = 0, out_right = out_length - 1;
    while (left <= right) {
        if (chars[left] == chars[right]) { palindrome[out_left] = chars[left]; palindrome[out_right] = chars[right]; ++left; if (right == 0) break; --right; }
        else if (dp[left + 1][right] < dp[left][right - 1]) { palindrome[out_left] = chars[left]; palindrome[out_right] = chars[left]; ++left; }
        else { palindrome[out_left] = chars[right]; palindrome[out_right] = chars[right]; if (right == 0) break; --right; }
        ++out_left; if (out_right == 0) break; --out_right;
    }
    std::uint8_t payload[MAX_OUTPUT]; std::size_t written = 0;
    written = write_i64(payload, written, static_cast<std::int64_t>(insertions));
    written = write_i64(payload, written, static_cast<std::int64_t>(out_length));
    std::memcpy(payload + written, palindrome, out_length); written += out_length;
    if (output == nullptr || capacity < written) return -2;
    std::memcpy(output, payload, written); return static_cast<std::int64_t>(written);
}
