#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 12;
constexpr std::size_t max_input_length = 27;
constexpr std::int64_t ratio_base = 120'001;

std::int64_t gcd_positive(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t choose_small(std::size_t n, std::size_t k) noexcept {
    if (k > n - k) k = n - k;
    std::int64_t result = 1;
    for (std::size_t index = 1; index <= k; ++index)
        result = result * static_cast<std::int64_t>(n - k + index) / static_cast<std::int64_t>(index);
    return result;
}

bool score_precedes(std::size_t candidate, std::size_t current,
                    const std::array<std::int64_t, max_items>& scores) noexcept {
    if (scores[candidate] != scores[current]) return scores[candidate] > scores[current];
    return candidate < current;
}
}

extern "C" std::int64_t dinkelbach_fixed_cardinality_ratio(const std::int64_t* input,
                                                           std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto n_value = input[0];
    const auto k_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_items) ||
        k_value < 1 || k_value > n_value ||
        length != 2 + 2 * static_cast<std::size_t>(n_value)) return -1;

    const auto n = static_cast<std::size_t>(n_value);
    const auto k = static_cast<std::size_t>(k_value);
    std::array<std::int64_t, max_items> numerators{};
    std::array<std::int64_t, max_items> denominators{};
    for (std::size_t item = 0; item < n; ++item) {
        const auto numerator = input[2 + 2 * item];
        const auto denominator = input[3 + 2 * item];
        if (numerator < 0 || numerator > 10'000 || denominator < 1 || denominator > 10'000)
            return -1;
        numerators[item] = numerator;
        denominators[item] = denominator;
    }

    std::int64_t ratio_numerator = 0;
    std::int64_t ratio_denominator = 1;
    const auto iteration_limit = choose_small(n, k) + 1;
    for (std::int64_t iteration = 0; iteration < iteration_limit; ++iteration) {
        std::array<std::int64_t, max_items> scores{};
        std::array<std::size_t, max_items> order{};
        for (std::size_t item = 0; item < n; ++item) {
            scores[item] = numerators[item] * ratio_denominator -
                           ratio_numerator * denominators[item];
            order[item] = item;
        }
        for (std::size_t item = 1; item < n; ++item) {
            const auto current = order[item];
            auto position = item;
            while (position > 0 && score_precedes(current, order[position - 1], scores)) {
                order[position] = order[position - 1];
                --position;
            }
            order[position] = current;
        }

        std::int64_t selected_numerator = 0;
        std::int64_t selected_denominator = 0;
        for (std::size_t rank = 0; rank < k; ++rank) {
            const auto item = order[rank];
            selected_numerator += numerators[item];
            selected_denominator += denominators[item];
        }
        const auto residual = selected_numerator * ratio_denominator -
                              ratio_numerator * selected_denominator;
        if (residual < 0) return -1;
        if (residual == 0) {
            const auto divisor = gcd_positive(selected_numerator, selected_denominator);
            return (selected_numerator / divisor) * ratio_base + selected_denominator / divisor;
        }

        const auto divisor = gcd_positive(selected_numerator, selected_denominator);
        ratio_numerator = selected_numerator / divisor;
        ratio_denominator = selected_denominator / divisor;
    }
    return -1;
}
