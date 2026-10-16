#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 256;
constexpr std::size_t max_input_length = max_values + 2;

void sift_down(std::int64_t *values, std::size_t root_start, std::size_t end) {
    auto root = root_start;
    while (root < end / 2) {
        auto child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const auto temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

void heap_sort(std::int64_t *values, std::size_t length) {
    for (std::size_t start = length / 2; start > 0; --start)
        sift_down(values, start - 1, length);
    for (std::size_t end = length; end > 1; --end) {
        const auto temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}
}

extern "C" std::int64_t two_pointers_pair_count(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto target = input[0], count_value = input[1];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(max_values) ||
        length != 2 + static_cast<std::size_t>(count_value) ||
        target < -2000000 || target > 2000000) return -1;

    const auto count = static_cast<std::size_t>(count_value);
    std::int64_t values[max_values]{};
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[2 + index];
        if (value < -1000000 || value > 1000000) return -1;
        values[index] = value;
    }
    heap_sort(values, count);
    if (count < 2) return 0;
    for (std::size_t index = 1; index < count; ++index)
        if (values[index - 1] == values[index]) return -1;

    std::size_t left = 0, right = count - 1;
    std::int64_t pairs = 0;
    while (left < right) {
        const auto sum = values[left] + values[right];
        if (sum < target) {
            ++left;
        } else if (sum > target) {
            --right;
        } else {
            ++pairs;
            ++left;
        }
    }
    return pairs;
}

