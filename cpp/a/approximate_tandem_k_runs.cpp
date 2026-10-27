#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TEXT = 24, MAX_INPUT = 26, MAX_OUTPUT = 34504;
std::size_t max_window_mismatches(const std::int64_t *text, std::size_t start,
                                 std::size_t length, std::size_t period) {
    std::size_t maximum = 0;
    const auto windows = length - 2 * period + 1;
    for (std::size_t window = 0; window < windows; ++window) {
        std::size_t count = 0;
        for (std::size_t offset = 0; offset < period; ++offset)
            count += text[start + window + offset] != text[start + window + period + offset];
        if (count > maximum) maximum = count;
    }
    return maximum;
}

std::size_t count_records(const std::int64_t *text, std::size_t n, std::size_t budget) {
    std::size_t count = 0;
    for (std::size_t start = 0; start < n; ++start) {
        const auto remaining = n - start;
        for (std::size_t period = 1; 2 * period + 1 <= remaining; ++period)
            for (std::size_t length = 2 * period + 1; length <= remaining; ++length)
                count += max_window_mismatches(text, start, length, period) <= budget;
    }
    return count;
}
void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t approximate_tandem_k_runs(
    const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 5 || length > MAX_INPUT) return -1;
    const auto n0 = input[0], budget0 = input[1];
    if (n0 < 3 || n0 > MAX_TEXT || budget0 < 0 || budget0 > 8 || length != static_cast<std::size_t>(n0) + 2) return -1;
    const auto n = static_cast<std::size_t>(n0), budget = static_cast<std::size_t>(budget0);
    const auto *text = input + 2;
    for (std::size_t i = 0; i < n; ++i) if (text[i] < 0 || text[i] > 3) return -1;
    const auto count = count_records(text, n, budget);
    const auto bytes = 8 * (1 + 4 * count);
    if (bytes > MAX_OUTPUT) return -1;
    if (!output || capacity < bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(count));
    std::size_t record = 0;
    for (std::size_t start = 0; start < n; ++start) {
        const auto remaining = n - start;
        for (std::size_t period = 1; 2 * period + 1 <= remaining; ++period)
            for (std::size_t factor_length = 2 * period + 1; factor_length <= remaining; ++factor_length) {
                const auto errors = max_window_mismatches(text, start, factor_length, period);
                if (errors <= budget) {
                    const auto offset = 8 * (1 + 4 * record++);
                    store_i64_le(output, offset, static_cast<std::int64_t>(start));
                    store_i64_le(output, offset + 8, static_cast<std::int64_t>(factor_length));
                    store_i64_le(output, offset + 16, static_cast<std::int64_t>(period));
                    store_i64_le(output, offset + 24, static_cast<std::int64_t>(errors));
                }
            }
    }
    return static_cast<std::int64_t>(bytes);
}
