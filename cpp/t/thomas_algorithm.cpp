#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 32;

void put_f64_le(std::uint8_t *output, std::size_t offset, double value) {
    union Bits { double floating; std::uint64_t integer; } bits{value};
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits.integer >> (8 * byte));
}
}

extern "C" std::int64_t thomas_algorithm(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 5 || length > 1 + 4 * kMaxN) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != 1 + 4 * n) return -1;

    const auto *lower = input + 1;
    const auto *diagonal = lower + n;
    const auto *upper = diagonal + n;
    const auto *rhs = upper + n;
    if (lower[0] != 0 || upper[n - 1] != 0) return -1;
    for (std::size_t row = 0; row < n; ++row) {
        if (lower[row] < -16 || lower[row] > 16 || upper[row] < -16 || upper[row] > 16 ||
            diagonal[row] < 17 || diagonal[row] > 64 || rhs[row] < -1000 || rhs[row] > 1000)
            return -1;
        const auto lower_abs = lower[row] < 0 ? -lower[row] : lower[row];
        const auto upper_abs = upper[row] < 0 ? -upper[row] : upper[row];
        if (diagonal[row] <= lower_abs + upper_abs) return -1;
    }
    const auto output_bytes = n * 8;
    if (output == nullptr || capacity < output_bytes) return -2;

    double modified_upper[kMaxN]{};
    double modified_rhs[kMaxN]{};
    double solution[kMaxN]{};
    modified_upper[0] = static_cast<double>(upper[0]) / static_cast<double>(diagonal[0]);
    modified_rhs[0] = static_cast<double>(rhs[0]) / static_cast<double>(diagonal[0]);
    for (std::size_t row = 1; row < n; ++row) {
        const double pivot = static_cast<double>(diagonal[row]) -
            static_cast<double>(lower[row]) * modified_upper[row - 1];
        if (row + 1 < n) modified_upper[row] = static_cast<double>(upper[row]) / pivot;
        modified_rhs[row] = (static_cast<double>(rhs[row]) -
            static_cast<double>(lower[row]) * modified_rhs[row - 1]) / pivot;
    }
    solution[n - 1] = modified_rhs[n - 1];
    for (std::size_t row = n - 1; row-- > 0;)
        solution[row] = modified_rhs[row] - modified_upper[row] * solution[row + 1];
    for (std::size_t row = 0; row < n; ++row)
        put_f64_le(output, row * 8, solution[row]);
    return static_cast<std::int64_t>(output_bytes);
}
