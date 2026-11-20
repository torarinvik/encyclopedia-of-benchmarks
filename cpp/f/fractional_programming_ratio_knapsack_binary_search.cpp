#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 12;
constexpr std::size_t max_weight = 32;
constexpr std::size_t max_parseable_input = 27;
constexpr std::int64_t scale = 1'000'000;
constexpr std::int64_t max_scaled_ratio = 1'000'000'000;
constexpr std::int64_t negative_infinity = INT64_MIN / 4;

bool ratio_feasible(const std::array<std::int64_t, max_items>& numerators,
                    const std::array<std::int64_t, max_items>& denominators,
                    std::size_t n, std::size_t required_weight,
                    std::int64_t threshold) noexcept {
    std::array<std::int64_t, max_weight + 1> current{};
    std::array<std::int64_t, max_weight + 1> next{};
    for (std::size_t weight = 0; weight <= required_weight; ++weight)
        current[weight] = negative_infinity;
    current[0] = 0;

    for (std::size_t item = 0; item < n; ++item) {
        for (std::size_t weight = 0; weight <= required_weight; ++weight)
            next[weight] = current[weight];
        const auto score = scale * numerators[item] - threshold * denominators[item];
        for (std::size_t weight = 0; weight <= required_weight; ++weight) {
            if (current[weight] == negative_infinity) continue;
            const auto sum = weight + static_cast<std::size_t>(denominators[item]);
            const auto target = sum < required_weight ? sum : required_weight;
            const auto candidate = current[weight] + score;
            if (candidate > next[target]) next[target] = candidate;
        }
        current = next;
    }
    return current[required_weight] >= 0;
}
}

extern "C" std::int64_t fractional_programming_ratio_knapsack_binary_search(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_parseable_input) return -1;
    const auto n_value = input[0];
    const auto required_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_items) ||
        required_value < 1 || required_value > static_cast<std::int64_t>(max_weight) ||
        length != 2 + 2 * static_cast<std::size_t>(n_value)) return -1;

    const auto n = static_cast<std::size_t>(n_value);
    const auto required_weight = static_cast<std::size_t>(required_value);
    std::array<std::int64_t, max_items> numerators{};
    std::array<std::int64_t, max_items> denominators{};
    std::int64_t denominator_sum = 0;
    for (std::size_t item = 0; item < n; ++item) {
        const auto numerator = input[2 + 2 * item];
        const auto denominator = input[3 + 2 * item];
        if (numerator < 0 || numerator > 1000 || denominator < 1 || denominator > 8)
            return -1;
        numerators[item] = numerator;
        denominators[item] = denominator;
        denominator_sum += denominator;
    }
    if (required_value > denominator_sum) return -1;

    std::int64_t low = 0;
    std::int64_t high = max_scaled_ratio + 1;
    while (high - low > 1) {
        const auto middle = low + (high - low) / 2;
        if (ratio_feasible(numerators, denominators, n, required_weight, middle))
            low = middle;
        else
            high = middle;
    }
    return low;
}
