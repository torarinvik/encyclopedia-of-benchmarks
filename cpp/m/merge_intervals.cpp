#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_intervals = 256;
constexpr std::size_t max_input_length = 1 + 2 * max_intervals;

struct Interval {
    std::int32_t start;
    std::int32_t end;
};

void store_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
} // namespace

extern "C" std::int64_t merge_intervals(const std::int64_t *values, std::size_t length,
                                        std::uint8_t *output, std::size_t capacity) {
    if (values == nullptr || length < 1 || length > max_input_length) return -1;
    const auto raw_count = values[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_intervals) ||
        length != 1 + 2 * static_cast<std::size_t>(raw_count)) return -1;

    const auto count = static_cast<std::size_t>(raw_count);
    std::array<Interval, max_intervals> intervals{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto start = values[1 + 2 * i];
        const auto end = values[2 + 2 * i];
        if (start < INT32_MIN || start > INT32_MAX ||
            end < INT32_MIN || end > INT32_MAX || start > end) return -1;
        intervals[i] = {static_cast<std::int32_t>(start), static_cast<std::int32_t>(end)};
    }

    std::sort(intervals.begin(), intervals.begin() + count,
              [](const Interval &a, const Interval &b) { return a.start < b.start; });
    std::size_t merged = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (merged != 0 && intervals[i].start <= intervals[merged - 1].end) {
            if (intervals[i].end > intervals[merged - 1].end)
                intervals[merged - 1].end = intervals[i].end;
        } else {
            intervals[merged++] = intervals[i];
        }
    }

    const auto byte_count = 8 * merged;
    if (output == nullptr || capacity < byte_count) return -2;
    for (std::size_t i = 0; i < merged; ++i) {
        store_i32_le(output, 8 * i, intervals[i].start);
        store_i32_le(output, 8 * i + 4, intervals[i].end);
    }
    return static_cast<std::int64_t>(byte_count);
}
