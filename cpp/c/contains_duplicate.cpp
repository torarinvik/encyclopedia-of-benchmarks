/* Sort a private copy, then scan neighbors for duplicates. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;
void sift_down(std::int64_t *values, std::size_t root, std::size_t length) noexcept {
    while (root < length / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < length && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const auto temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}
}

// Accepts signed 32-bit values; returns 1 if any repeat, 0 otherwise, -1 if invalid.
extern "C" std::int64_t contains_duplicate(const std::int64_t *input,
                                            std::size_t length) noexcept {
    if (length > max_values || (length != 0 && input == nullptr)) return -1;
    std::int64_t values[max_values];
    for (std::size_t i = 0; i < length; ++i) {
        if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1;
        values[i] = input[i];
    }
    for (std::size_t start = length / 2; start > 0; --start) sift_down(values, start - 1, length);
    for (std::size_t end = length; end > 1; --end) {
        const auto temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
    for (std::size_t i = 1; i < length; ++i)
        if (values[i - 1] == values[i]) return 1;
    return 0;
}
