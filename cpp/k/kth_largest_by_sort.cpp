// Sort a local copy with portable heapsort, then index from the end.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_length = 512;
void sift_down(std::int32_t *values, std::size_t root, std::size_t end) noexcept {
    while (root < end / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const auto temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}
}

extern "C" std::int64_t kth_largest_by_sort(const std::int64_t *input,
    std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_length + 1) return -1;
    const std::size_t count = length - 1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(count)) return -1;
    std::int32_t values[max_length];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[index + 1];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max()) return -1;
        values[index] = static_cast<std::int32_t>(value);
    }
    for (std::size_t start = count / 2; start > 0; --start) sift_down(values, start - 1, count);
    for (std::size_t end = count; end > 1; --end) {
        const auto temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
    return values[count - static_cast<std::size_t>(input[0])];
}
