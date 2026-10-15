// Replace a permutation by its lexicographic successor, wrapping to minimum.
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t next_permutation(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    constexpr std::size_t max_length = 128;
    if (!input || length < 1 || length > max_length + 1) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_length) || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    std::int32_t values[max_length];
    for (std::size_t i = 0; i < n; ++i) {
        if (input[i + 1] < std::numeric_limits<std::int32_t>::min() || input[i + 1] > std::numeric_limits<std::int32_t>::max()) return -1;
        values[i] = static_cast<std::int32_t>(input[i + 1]);
    }
    const auto required = n * 4;
    if (output_capacity < required || (required != 0 && !output)) return -2;
    std::size_t pivot = n;
    for (std::size_t index = n; index > 1; --index) {
        if (values[index - 2] < values[index - 1]) { pivot = index - 2; break; }
    }
    if (pivot == n) {
        if (n > 1) std::reverse(values, values + n);
    } else {
        std::size_t successor = n - 1;
        while (values[successor] <= values[pivot]) --successor;
        std::swap(values[pivot], values[successor]);
        std::reverse(values + pivot + 1, values + n);
    }
    for (std::size_t i = 0; i < n; ++i) {
        const auto bits = static_cast<std::uint32_t>(values[i]);
        for (std::size_t byte = 0; byte < 4; ++byte) output[i * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(n);
}
