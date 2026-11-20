#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 64;
constexpr std::size_t max_input_length = 67;
constexpr std::size_t sample_threshold = 24;

std::int64_t select_kth(std::int64_t *values, std::size_t left,
                        std::size_t right, std::size_t target)
{
    while (true) {
        if (right - left > sample_threshold) {
            const std::size_t size = right - left + 1;
            const std::size_t relative_rank = target - left + 1;
            const double z = std::sqrt(std::log(static_cast<double>(size)));
            const double sample_size = 0.5 * std::exp(2.0 * z / 3.0);
            double direction = 0.0;
            if (2 * relative_rank < size) direction = -1.0;
            else if (2 * relative_rank > size) direction = 1.0;
            const double spread = 0.5 * std::sqrt(
                z * sample_size * (static_cast<double>(size) - sample_size)
                    / static_cast<double>(size)
            ) * direction;
            const double lower_estimate = static_cast<double>(target)
                - static_cast<double>(relative_rank) * sample_size / static_cast<double>(size)
                + spread;
            const double upper_estimate = static_cast<double>(target)
                + static_cast<double>(size - relative_rank) * sample_size / static_cast<double>(size)
                + spread;

            std::int64_t sample_left_value = static_cast<std::int64_t>(std::floor(lower_estimate));
            sample_left_value = std::max(sample_left_value, static_cast<std::int64_t>(left));
            sample_left_value = std::max(sample_left_value, static_cast<std::int64_t>(target));
            std::int64_t sample_right_value = static_cast<std::int64_t>(std::ceil(upper_estimate));
            sample_right_value = std::min(sample_right_value, static_cast<std::int64_t>(right));
            sample_right_value = std::max(sample_right_value, static_cast<std::int64_t>(target));
            const std::size_t sample_left = static_cast<std::size_t>(sample_left_value);
            const std::size_t sample_right = static_cast<std::size_t>(sample_right_value);
            (void)select_kth(values, sample_left, sample_right, target);
        }

        const std::int64_t pivot = values[target];
        std::size_t less = left;
        std::size_t scan = left;
        std::size_t greater = right + 1;
        while (scan < greater) {
            if (values[scan] < pivot) {
                const std::int64_t temporary = values[less];
                values[less++] = values[scan];
                values[scan++] = temporary;
            } else if (values[scan] > pivot) {
                const std::int64_t temporary = values[--greater];
                values[greater] = values[scan];
                values[scan] = temporary;
            } else {
                ++scan;
            }
        }
        if (target < less) right = less - 1;
        else if (target >= greater) left = greater;
        else return pivot;
    }
}
}

extern "C" std::int64_t floyd_rivest_select(const std::int64_t *input,
                                             std::size_t length) noexcept
{
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    const std::int64_t count_value = input[0];
    const std::int64_t rank_value = input[1];
    if (count_value < 1 || count_value > static_cast<std::int64_t>(max_values) ||
        rank_value < 0 || rank_value >= count_value ||
        length != static_cast<std::size_t>(count_value) + 2) return -1;

    const std::size_t count = static_cast<std::size_t>(count_value);
    std::int64_t values[max_values];
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 2];
        if (value < 0 || value > INT32_MAX) return -1;
        for (std::size_t previous = 0; previous < index; ++previous) {
            if (values[previous] == value) return -1;
        }
        values[index] = value;
    }
    return select_kth(values, 0, count - 1, static_cast<std::size_t>(rank_value));
}
