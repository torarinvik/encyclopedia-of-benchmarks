#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_boxes = 18;
constexpr std::size_t max_parseable_length = max_boxes + 2;
constexpr std::size_t max_memo = max_boxes * max_boxes * (max_boxes + 1);

std::int64_t solve_boxes(std::size_t left, std::size_t right, std::size_t carry,
                         const std::int64_t *colors, const std::size_t *counts,
                         std::int64_t *memo) {
    if (left > right) return 0;
    const std::size_t index = (left * max_boxes + right) * (max_boxes + 1) + carry;
    if (memo[index] >= 0) return memo[index];
    const std::size_t attached = counts[left] + carry;
    std::int64_t best = static_cast<std::int64_t>(attached * attached)
        + solve_boxes(left + 1, right, 0, colors, counts, memo);
    for (std::size_t later = left + 1; later <= right; ++later) {
        if (colors[later] == colors[left]) {
            const std::int64_t joined = solve_boxes(left + 1, later - 1, 0, colors, counts, memo)
                + solve_boxes(later, right, attached, colors, counts, memo);
            if (joined > best) best = joined;
        }
    }
    memo[index] = best;
    return best;
}
}

extern "C" std::int64_t remove_boxes(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 1 || length > max_parseable_length) return -1;
    const std::int64_t n_raw = values[0];
    if (n_raw < 0 || n_raw > static_cast<std::int64_t>(max_boxes)
        || length != static_cast<std::size_t>(n_raw) + 1) return -1;
    const std::size_t n = static_cast<std::size_t>(n_raw);
    std::int64_t colors[max_boxes]{};
    std::size_t counts[max_boxes]{};
    std::size_t groups = 0;
    for (std::size_t index = 0; index < n; ++index) {
        const std::int64_t color = values[index + 1];
        if (color < 0 || color > 7) return -1;
        if (groups != 0 && colors[groups - 1] == color) {
            ++counts[groups - 1];
        } else {
            colors[groups] = color;
            counts[groups] = 1;
            ++groups;
        }
    }
    if (groups == 0) return 0;
    std::int64_t memo[max_memo];
    for (std::size_t index = 0; index < max_memo; ++index) memo[index] = -1;
    return solve_boxes(0, groups - 1, 0, colors, counts, memo);
}
