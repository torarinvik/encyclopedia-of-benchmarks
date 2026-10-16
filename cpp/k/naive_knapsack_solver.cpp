#include <cstddef>
#include <cstdint>

extern "C" std::int64_t naive_knapsack_solver(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || length > 32) return -1;
    const auto capacity = values[0], count = values[1];
    if (capacity < 0 || capacity > 1000000 || count < 0 || count > 30 || length != static_cast<std::size_t>(count) + 2) return -1;
    std::int64_t weight = 0, mask = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i) {
        const auto item = values[i + 2];
        if (item < 0 || item > 1000000) return -1;
        if (weight + item <= capacity) { weight += item; mask |= std::int64_t{1} << i; }
    }
    return mask;
}
