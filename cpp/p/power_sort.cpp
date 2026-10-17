#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 64;
constexpr std::size_t max_input_values = 67;
constexpr std::int64_t min_value = -1'000'000;
constexpr std::int64_t max_value = 1'000'000;

struct Run {
    std::size_t start;
    std::size_t length;
    std::int64_t power;
};

bool key_less(std::int64_t left, std::int64_t right, bool reverse) noexcept {
    return reverse ? left > right : left < right;
}

std::size_t find_run(std::int64_t *values, std::size_t start, std::size_t end, bool reverse) noexcept {
    if (start >= end - 1) return start + 1;
    std::size_t run_end = start + 1;
    if (key_less(values[run_end], values[start], reverse)) {
        while (run_end < end && key_less(values[run_end], values[run_end - 1], reverse)) ++run_end;
        for (std::size_t left = start, right = run_end - 1; left < right; ++left, --right) {
            const auto temporary = values[left];
            values[left] = values[right];
            values[right] = temporary;
        }
    } else {
        while (run_end < end && !key_less(values[run_end], values[run_end - 1], reverse)) ++run_end;
    }
    return run_end;
}

std::int64_t node_power(std::size_t total_length, std::size_t b1, std::size_t n1,
                       std::size_t b2, std::size_t n2) noexcept {
    const auto a = static_cast<std::int64_t>(2 * b1 + n1);
    const auto b = static_cast<std::int64_t>(2 * b2 + n2);
    const auto denominator = static_cast<std::int64_t>(2 * total_length);
    std::int64_t power = 0;
    while ((a * (std::int64_t{1} << power)) / denominator ==
           (b * (std::int64_t{1} << power)) / denominator) ++power;
    return power;
}

void merge_runs(std::int64_t *values, std::size_t start1, std::size_t end1,
                std::size_t end2, bool reverse) noexcept {
    std::int64_t left[max_values];
    std::int64_t right[max_values];
    const auto left_length = end1 - start1;
    const auto right_length = end2 - end1;
    for (std::size_t index = 0; index < left_length; ++index) left[index] = values[start1 + index];
    for (std::size_t index = 0; index < right_length; ++index) right[index] = values[end1 + index];
    std::size_t i = 0, j = 0, output = start1;
    while (i < left_length && j < right_length) {
        const bool take_left = reverse ? left[i] >= right[j] : left[i] <= right[j];
        values[output++] = take_left ? left[i++] : right[j++];
    }
    while (i < left_length) values[output++] = left[i++];
    while (j < right_length) values[output++] = right[j++];
}

void power_sort_impl(std::int64_t *values, std::size_t length, bool reverse) noexcept {
    if (length <= 1) return;
    Run stack[max_values];
    std::size_t stack_size = 0;
    std::size_t start = 0;
    while (start < length) {
        const auto run_end = find_run(values, start, length, reverse);
        auto run_length = run_end - start;
        auto power = stack_size == 0 ? 0 : node_power(length, stack[stack_size - 1].start,
            stack[stack_size - 1].length, start, run_length);
        while (stack_size > 0 && stack[stack_size - 1].power >= power) {
            const auto previous = stack[--stack_size];
            merge_runs(values, previous.start, previous.start + previous.length, run_end, reverse);
            start = previous.start;
            run_length = run_end - start;
            power = stack_size == 0 ? 0 : node_power(length, stack[stack_size - 1].start,
                stack[stack_size - 1].length, start, run_length);
        }
        stack[stack_size++] = Run{start, run_length, power};
        start = run_end;
    }
    while (stack_size > 1) {
        const auto right = stack[--stack_size];
        const auto left = stack[--stack_size];
        const auto merged_end = right.start + right.length;
        merge_runs(values, left.start, left.start + left.length, merged_end, reverse);
        const auto merged_length = merged_end - left.start;
        const auto power = stack_size == 0 ? 0 : node_power(length, stack[stack_size - 1].start,
            stack[stack_size - 1].length, left.start, merged_length);
        stack[stack_size++] = Run{left.start, merged_length, power};
    }
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t power_sort(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto reverse_value = input[0];
    const auto count_value = input[1];
    if ((reverse_value != 0 && reverse_value != 1) || count_value < 0 || count_value > static_cast<std::int64_t>(max_values)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 2 + count) return -1;
    std::int64_t values[max_values];
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[2 + index];
        if (value < min_value || value > max_value) return -1;
        values[index] = value;
    }
    if (count == 0) return 0;
    const auto output_bytes = 8 * count;
    if (output == nullptr || capacity < output_bytes) return -2;
    power_sort_impl(values, count, reverse_value == 1);
    for (std::size_t index = 0; index < count; ++index) write_i64_le(output, 8 * index, values[index]);
    return static_cast<std::int64_t>(output_bytes);
}
