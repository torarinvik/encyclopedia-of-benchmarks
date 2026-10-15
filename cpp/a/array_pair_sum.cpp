// Sort signed 32-bit values and sum the first of every adjacent pair.
#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

static void sift_down(std::array<std::int64_t, max_length>& values,
    std::size_t root, std::size_t count) noexcept {
    while (root * 2 + 1 < count) {
        auto child = root * 2 + 1;
        if (child + 1 < count && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) return;
        const auto temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

extern "C" std::int64_t array_pair_sum(const std::int64_t *input,
    std::size_t length) noexcept {
    if (length > max_length || length % 2 != 0 || (length != 0 && input == nullptr)) return -1;
    std::array<std::int64_t, max_length> values{};
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] < -2147483648LL || input[index] > 2147483647LL) return -1;
        values[index] = input[index];
    }
    for (std::size_t start = length / 2; start > 0; --start) sift_down(values, start - 1, length);
    for (std::size_t end = length; end > 1; --end) {
        const auto temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
    std::int64_t total = 0;
    for (std::size_t index = 0; index < length; index += 2) total += values[index];
    return total;
}
