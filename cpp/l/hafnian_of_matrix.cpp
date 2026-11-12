#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 16;
constexpr std::int64_t kMod = 998244353;
constexpr std::size_t kStates = std::size_t{1} << kMaxN;

void store_i64_le(std::uint8_t *output, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t hafnian_of_matrix(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > 1 + kMaxN * kMaxN) return -1;
    const auto n_value = input[0];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(kMaxN) || n_value % 2 != 0)
        return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + n * n) return -1;

    std::array<std::int64_t, kMaxN * kMaxN> matrix{};
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const auto value = input[1 + row * n + column];
            if (value < 0 || value >= kMod || (row == column && value != 0)) return -1;
            matrix[row * n + column] = value;
        }
    }
    for (std::size_t row = 0; row < n; ++row)
        for (std::size_t column = 0; column < row; ++column)
            if (matrix[row * n + column] != matrix[column * n + row]) return -1;

    std::array<std::int64_t, kStates> dp{};
    dp[0] = 1;
    const auto full = (std::size_t{1} << n) - 1;
    for (std::size_t mask = 1; mask <= full; ++mask) {
        auto bits = mask;
        bool odd = false;
        while (bits != 0) {
            odd = !odd;
            bits &= bits - 1;
        }
        if (odd) continue;
        std::size_t first = 0;
        while ((mask & (std::size_t{1} << first)) == 0) ++first;
        const auto without_first = mask ^ (std::size_t{1} << first);
        for (std::size_t second = first + 1; second < n; ++second) {
            const auto bit = std::size_t{1} << second;
            if ((without_first & bit) == 0) continue;
            const auto rest = without_first ^ bit;
            dp[mask] = (dp[mask] + matrix[first * n + second] * dp[rest]) % kMod;
        }
    }
    if (output == nullptr || capacity < 8) return -2;
    store_i64_le(output, dp[full]);
    return 8;
}
