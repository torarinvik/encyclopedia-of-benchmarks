#include <cstddef>
#include <cstdint>

extern "C" std::int64_t functional_graph_cycle_brent(const std::int64_t* input, std::size_t length) {
    if (!input || length < 3 || length > 67) return -1;
    const auto n = input[0], start_value = input[1];
    if (n < 1 || n > 64 || start_value < 0 || start_value >= n || length != static_cast<std::size_t>(n) + 2) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(n); ++i)
        if (input[i + 2] < 0 || input[i + 2] >= n) return -1;
    const auto next = [input](std::size_t v) { return static_cast<std::size_t>(input[v + 2]); };
    const auto start = static_cast<std::size_t>(start_value);
    std::size_t checkpoint = start, moving = next(start), power = 1, period = 1;
    while (checkpoint != moving) {
        if (power == period) { checkpoint = moving; power *= 2; period = 0; }
        moving = next(moving); ++period;
    }
    std::size_t left = start, right = start;
    for (std::size_t i = 0; i < period; ++i) right = next(right);
    std::size_t tail = 0;
    while (left != right) { left = next(left); right = next(right); ++tail; }
    return static_cast<std::int64_t>(65 * tail + period);
}
