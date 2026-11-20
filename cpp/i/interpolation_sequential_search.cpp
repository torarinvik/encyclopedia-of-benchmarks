#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64;
constexpr std::int64_t MIN_VALUE = -1000000;
constexpr std::int64_t MAX_VALUE = 1000000;
}

extern "C" std::int64_t interpolation_sequential_search(const std::int64_t *input,
                                                           std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > MAX_N + 3) return -1;
    const std::int64_t count_value = input[0];
    const std::int64_t target = input[1];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(MAX_N)
            || length != static_cast<std::size_t>(count_value) + 2
            || target < MIN_VALUE || target > MAX_VALUE) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[i + 2];
        if (value < MIN_VALUE || value > MAX_VALUE
                || (i > 0 && input[i + 1] >= value)) return -1;
    }
    if (count == 0) return -1;
    const auto first = input[2];
    const auto last = input[count + 1];
    if (target < first || target > last) return -1;
    if (count == 1) return first == target ? 0 : -1;

    const auto position = static_cast<std::size_t>(
        ((target - first) * static_cast<std::int64_t>(count - 1)) / (last - first));
    const auto estimated = input[position + 2];
    if (estimated == target) return static_cast<std::int64_t>(position);
    if (estimated < target) {
        for (std::size_t i = position + 1; i < count; ++i) {
            const auto value = input[i + 2];
            if (value >= target) return value == target ? static_cast<std::int64_t>(i) : -1;
        }
    } else {
        auto i = position;
        while (i > 0) {
            --i;
            const auto value = input[i + 2];
            if (value <= target) return value == target ? static_cast<std::int64_t>(i) : -1;
        }
    }
    return -1;
}
