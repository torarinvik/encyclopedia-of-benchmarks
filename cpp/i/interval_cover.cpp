/* Greedy minimum subfamily covering a half-open target interval. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t interval_cover(const std::int64_t *input,
                                        std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > 36) return -2;
    const auto target_left = input[0];
    const auto target_right = input[1];
    const auto count_value = input[2];
    if (target_left < 0 || target_left > target_right || target_right > 32
        || count_value < 0 || count_value > 16) return -2;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 3 + 2 * count) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        const auto left = input[3 + 2 * i];
        const auto right = input[4 + 2 * i];
        if (left < 0 || left >= right || right > 32) return -2;
    }
    if (target_left == target_right) return 0;

    auto frontier = target_left;
    std::int64_t selected = 0;
    while (frontier < target_right) {
        auto farthest = frontier;
        for (std::size_t i = 0; i < count; ++i) {
            const auto left = input[3 + 2 * i];
            const auto right = input[4 + 2 * i];
            if (left <= frontier && right > farthest) farthest = right;
        }
        if (farthest == frontier) return -1;
        frontier = farthest;
        ++selected;
    }
    return selected;
}
