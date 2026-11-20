#include <array>
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_sites = 128;
constexpr std::size_t max_input_words = 130;

std::int64_t floor_div(std::int64_t numerator, std::int64_t denominator) {
    auto quotient = numerator / denominator;
    const auto remainder = numerator % denominator;
    if (remainder != 0 && numerator < 0) --quotient;
    return quotient;
}

void store_i64_le(std::uint8_t *output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t felzenszwalb_huttenlocher_1d_squared_distance_transform(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_words) return -1;
    const auto n64 = input[0];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(max_sites)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    if (length != n + 1) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 1'000'000) return -1;
    if (output == nullptr || output_capacity < n * 16) return -2;

    std::array<std::size_t, max_sites> sites{};
    std::array<std::int64_t, max_sites> starts{};
    std::size_t top = 0;
    sites[0] = 0;
    starts[0] = std::numeric_limits<std::int64_t>::min() / 2;
    for (std::size_t q = 1; q < n; ++q) {
        for (;;) {
            const auto p = sites[top];
            const auto numerator = input[q + 1] + static_cast<std::int64_t>(q * q)
                - input[p + 1] - static_cast<std::int64_t>(p * p);
            const auto denominator = static_cast<std::int64_t>(2 * (q - p));
            const auto first = floor_div(numerator, denominator) + 1;
            if (top == 0 || first > starts[top]) {
                ++top;
                sites[top] = q;
                starts[top] = first;
                break;
            }
            --top;
        }
    }

    std::size_t active = 0;
    for (std::size_t x = 0; x < n; ++x) {
        while (active < top && starts[active + 1] <= static_cast<std::int64_t>(x)) ++active;
        const auto site = sites[active];
        const auto delta = static_cast<std::int64_t>(x) - static_cast<std::int64_t>(site);
        const auto distance = delta * delta + input[site + 1];
        store_i64_le(output, 2 * x, distance);
        store_i64_le(output, 2 * x + 1, static_cast<std::int64_t>(site));
    }
    return static_cast<std::int64_t>(n * 16);
}
