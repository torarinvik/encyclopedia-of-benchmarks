#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_index = 17;
constexpr std::int64_t value_limit = 1000;

std::size_t encode(std::int64_t value, std::array<std::uint8_t, max_index>& output) noexcept {
    std::array<std::int64_t, max_index + 1> fib{};
    std::array<std::int64_t, max_index + 1> weight{};
    std::array<std::int64_t, max_index + 1> low{};
    std::array<std::int64_t, max_index + 1> high{};
    std::array<std::uint8_t, max_index + 1> digit{};
    fib[1] = fib[2] = 1;
    for (std::size_t k = 3; k <= max_index; ++k) fib[k] = fib[k - 1] + fib[k - 2];
    for (std::size_t k = 1; k <= max_index; ++k) weight[k] = k & 1 ? fib[k] : -fib[k];
    for (std::size_t k = 1; k <= max_index; ++k) {
        const auto suffix_low = k == 1 ? 0 : low[k - 2];
        const auto suffix_high = k == 1 ? 0 : high[k - 2];
        const auto with_top_low = weight[k] + suffix_low;
        const auto with_top_high = weight[k] + suffix_high;
        low[k] = low[k - 1] < with_top_low ? low[k - 1] : with_top_low;
        high[k] = high[k - 1] > with_top_high ? high[k - 1] : with_top_high;
    }
    auto remaining = value;
    bool selected_above = false;
    for (std::size_t k = max_index; k > 0; --k) {
        bool choose = false;
        if (!selected_above) {
            const auto suffix_low = k == 1 ? 0 : low[k - 2];
            const auto suffix_high = k == 1 ? 0 : high[k - 2];
            const auto candidate = remaining - weight[k];
            choose = suffix_low <= candidate && candidate <= suffix_high;
        }
        if (choose) { digit[k] = 1; remaining -= weight[k]; }
        selected_above = choose;
    }
    std::size_t highest = max_index;
    while (highest > 1 && digit[highest] == 0) --highest;
    for (std::size_t k = highest; k > 0; --k)
        output[highest - k] = static_cast<std::uint8_t>(digit[k] ? '1' : '0');
    return highest;
}
}

extern "C" std::int64_t negafibonacci_representation(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 1 || input[0] < -value_limit || input[0] > value_limit) return -1;
    std::array<std::uint8_t, max_index> staged{};
    const auto required = encode(input[0], staged);
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < required; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(required);
}
