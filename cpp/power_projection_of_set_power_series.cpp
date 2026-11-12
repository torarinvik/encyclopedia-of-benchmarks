#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t modulus = 998244353;
constexpr std::size_t max_n = 4;
constexpr std::size_t max_m = 8;
constexpr std::size_t max_size = 16;
constexpr std::size_t max_input = 35;

void store_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t power_projection_of_set_power_series(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_n) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_m)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    const auto powers = static_cast<std::size_t>(input[1]);
    const std::size_t size = std::size_t{1} << n;
    if (length != 2 + 2 * size) return -1;

    std::int64_t series[max_size]{};
    std::int64_t weights[max_size]{};
    for (std::size_t mask = 0; mask < size; ++mask) {
        const auto a = input[2 + mask];
        const auto w = input[2 + size + mask];
        if (a < 0 || a >= modulus || w < 0 || w >= modulus) return -1;
        series[mask] = a;
        weights[mask] = w;
    }

    const std::size_t bytes = 8 * powers;
    if (output == nullptr || capacity < bytes) return -2;

    std::int64_t first[max_size]{};
    std::int64_t second[max_size]{};
    auto* current = first;
    auto* next = second;
    current[0] = 1;
    for (std::size_t power = 0; power < powers; ++power) {
        std::int64_t projection = 0;
        for (std::size_t mask = 0; mask < size; ++mask)
            projection = (projection + weights[mask] * current[mask]) % modulus;
        store_le(output, 8 * power, projection);
        if (power + 1 == powers) break;
        for (std::size_t mask = 0; mask < size; ++mask) {
            std::int64_t total = 0;
            std::size_t subset = mask;
            for (;;) {
                total = (total + current[subset] * series[mask ^ subset]) % modulus;
                if (subset == 0) break;
                subset = (subset - 1) & mask;
            }
            next[mask] = total;
        }
        auto* temporary = current;
        current = next;
        next = temporary;
    }
    return static_cast<std::int64_t>(bytes);
}
