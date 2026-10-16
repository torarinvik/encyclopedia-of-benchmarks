#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_array_length = 64;
constexpr std::size_t max_input_length = 67;

std::int64_t search_segment(const std::int64_t *values, std::size_t begin,
                            std::size_t length, std::int64_t target,
                            std::size_t offset) noexcept {
    if (length == 0) return -1;
    const std::int64_t first = values[begin];
    const std::int64_t last = values[begin + length - 1];
    if (target < first || target > last) return -1;
    if (first == last) return target == first ? static_cast<std::int64_t>(offset) : -1;

    const auto interpolation = static_cast<std::size_t>(
        static_cast<std::int64_t>(length - 1) * (target - first) / (last - first));
    const std::size_t midpoint = length / 2;
    const std::size_t left = interpolation > midpoint ? midpoint : interpolation;
    const std::size_t right = interpolation > midpoint ? interpolation : midpoint;
    std::size_t from, to;
    if (target < values[begin + left]) {
        if (left == 0) return -1;
        from = 0;
        to = left - 1;
    } else if (target < values[begin + right]) {
        from = left;
        to = right - 1;
    } else {
        from = right;
        to = length - 1;
    }
    if (to < from) return -1;
    return search_segment(values, begin + from, to - from + 1, target, offset + from);
}
}

extern "C" std::int64_t fast_searcher(const std::int64_t *input,
                                      std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -2;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_array_length)) return -2;
    const auto count = static_cast<std::size_t>(input[0]);
    if (length != count + 2) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[1 + i];
        if (value < -1000 || value > 1000) return -2;
        if (i > 0 && input[i] >= value) return -2;
    }
    const auto target = input[length - 1];
    if (target < -1000 || target > 1000) return -2;
    return search_segment(input, 1, count, target, 0);
}
