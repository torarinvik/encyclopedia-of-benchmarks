#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_q = 8;
constexpr std::int64_t max_n = 10000;

std::int64_t integer_sqrt(std::int64_t value) noexcept {
    std::int64_t low = 0, high = value + 1;
    while (high - low > 1) {
        const auto middle = low + (high - low) / 2;
        if (middle * middle <= value) low = middle;
        else high = middle;
    }
    return low;
}

void write_u32(std::uint8_t *output, std::size_t offset, std::uint32_t value) noexcept {
    output[offset] = static_cast<std::uint8_t>(value);
    output[offset + 1] = static_cast<std::uint8_t>(value >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(value >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(value >> 24);
}
} // namespace

extern "C" std::int64_t two_square_sum(const std::int64_t *input,
                                        std::size_t length,
                                        std::uint8_t *output,
                                        std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_q + 1) return -1;
    const auto q64 = input[0];
    if (q64 < 1 || q64 > static_cast<std::int64_t>(max_q)) return -1;
    const auto q = static_cast<std::size_t>(q64);
    if (length != q + 1) return -1;

    std::int64_t numbers[max_q]{};
    std::size_t counts[max_q]{};
    std::size_t total_pairs = 0;
    for (std::size_t query = 0; query < q; ++query) {
        const auto n = input[query + 1];
        if (n < 0 || n > max_n) return -1;
        numbers[query] = n;
        for (std::int64_t a = 0; a * a <= n; ++a) {
            const auto remainder = n - a * a;
            const auto b = integer_sqrt(remainder);
            if (b * b == remainder) ++counts[query];
        }
        total_pairs += counts[query];
    }

    const auto required = 4 * (q + 2 * total_pairs);
    if (output == nullptr || capacity < required) return -2;
    std::size_t offset = 0;
    for (std::size_t query = 0; query < q; ++query) {
        write_u32(output, offset, static_cast<std::uint32_t>(counts[query]));
        offset += 4;
        const auto n = numbers[query];
        for (std::int64_t a = 0; a * a <= n; ++a) {
            const auto remainder = n - a * a;
            const auto b = integer_sqrt(remainder);
            if (b * b != remainder) continue;
            write_u32(output, offset, static_cast<std::uint32_t>(a));
            write_u32(output, offset + 4, static_cast<std::uint32_t>(b));
            offset += 8;
        }
    }
    return static_cast<std::int64_t>(offset);
}
