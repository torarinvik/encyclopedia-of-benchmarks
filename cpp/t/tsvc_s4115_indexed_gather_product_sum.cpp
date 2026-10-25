#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 1 + 3 * max_n;
constexpr std::int64_t max_value = 1'000'000;
}

extern "C" std::int64_t tsvc_s4115_indexed_gather_product_sum(
    const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 4 || length > max_input_length) return -1;
    const std::int64_t n_raw = input[0];
    if (n_raw < 1 || n_raw > static_cast<std::int64_t>(max_n)) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    if (length != 1 + 3 * n) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        const std::int64_t index = input[1 + i];
        const std::int64_t a_value = input[1 + n + i];
        const std::int64_t b_value = input[1 + 2 * n + i];
        if (index < 0 || index >= static_cast<std::int64_t>(n)) return -1;
        if (a_value < 0 || a_value > max_value || b_value < 0 || b_value > max_value) return -1;
    }

    std::int64_t sum = 0;
    for (std::size_t i = 0; i < n; ++i) {
        const std::size_t index = static_cast<std::size_t>(input[1 + i]);
        sum += input[1 + n + i] * input[1 + 2 * n + index];
    }
    return sum;
}
