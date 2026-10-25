#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 1 + max_n;
constexpr std::int64_t max_value = 1'000'000;
}

extern "C" std::int64_t tsvc_s3111_positive_value_sum(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0];
    if (n_raw < 0 || n_raw > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    if (length != 1 + n) return -1;

    std::int64_t sum = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t value = input[i + 1];
        if (value < -max_value || value > max_value) return -1;
        if (value > 0) sum += value;
    }
    return sum;
}
