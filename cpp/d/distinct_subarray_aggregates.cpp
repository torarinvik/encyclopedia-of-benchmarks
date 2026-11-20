#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 64, max_input = 67, max_segments = 65;

std::int64_t gcd_nonnegative(std::int64_t a, std::int64_t b) {
    while (b != 0) {
        const auto remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

std::int64_t combine_value(std::int64_t mode, std::int64_t a, std::int64_t b) {
    if (mode == 0) return gcd_nonnegative(a, b);
    if (mode == 1) return a | b;
    return a & b;
}
}

extern "C" std::int64_t distinct_subarray_aggregates(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto mode = input[0], n_value = input[1];
    if (mode < 0 || mode > 2 || n_value < 0 || n_value > max_n) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 2 + n) return -1;

    std::int64_t segment_value[max_segments], segment_left[max_segments], segment_right[max_segments];
    std::size_t segment_count = 0;
    std::int64_t aggregate_sum = 0, suffix_distinct_count = 0;
    for (std::size_t right = 0; right < n; ++right) {
        const auto value = input[2 + right];
        if (value < 0 || value > 255) return -1;
        for (std::size_t j = 0; j < segment_count; ++j)
            segment_value[j] = combine_value(mode, segment_value[j], value);
        segment_value[segment_count] = value;
        segment_left[segment_count] = static_cast<std::int64_t>(right);
        segment_right[segment_count] = static_cast<std::int64_t>(right);
        ++segment_count;

        std::size_t write = 0;
        for (std::size_t read = 0; read < segment_count; ++read) {
            if (write > 0 && segment_value[read] == segment_value[write - 1]) {
                segment_right[write - 1] = segment_right[read];
            } else {
                segment_value[write] = segment_value[read];
                segment_left[write] = segment_left[read];
                segment_right[write] = segment_right[read];
                ++write;
            }
        }
        segment_count = write;
        suffix_distinct_count += static_cast<std::int64_t>(segment_count);
        for (std::size_t j = 0; j < segment_count; ++j)
            aggregate_sum += segment_value[j] * (segment_right[j] - segment_left[j] + 1);
    }
    return aggregate_sum * 1024 + suffix_distinct_count;
}
