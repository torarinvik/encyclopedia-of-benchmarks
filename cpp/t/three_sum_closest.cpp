// Closest three-value sum, using a private heapsorted copy.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 512;
constexpr std::int64_t invalid_result = -9000000000000000000LL;
void heap_sift_down(std::int64_t *values, std::size_t root, std::size_t end) {
    while (root < end / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const std::int64_t temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}
void heap_sort(std::int64_t *values, std::size_t length) {
    for (std::size_t start = length / 2; start > 0; --start) heap_sift_down(values, start - 1, length);
    for (std::size_t end = length; end > 1; --end) {
        const std::int64_t temporary = values[0]; values[0] = values[end - 1]; values[end - 1] = temporary;
        heap_sift_down(values, 0, end - 1);
    }
}
std::int64_t absolute_difference(std::int64_t left, std::int64_t right) {
    const std::int64_t difference = left - right;
    return difference < 0 ? -difference : difference;
}
}

extern "C" std::int64_t three_sum_closest(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_items + 2) return invalid_result;
    const std::int64_t target = input[0], count_value = input[1];
    if (target < INT32_MIN || target > INT32_MAX || count_value < 3 || count_value > static_cast<std::int64_t>(max_items))
        return invalid_result;
    const std::size_t count = static_cast<std::size_t>(count_value);
    if (length != count + 2) return invalid_result;
    std::int64_t values[max_items];
    for (std::size_t index = 0; index < count; ++index) {
        const std::int64_t value = input[index + 2];
        if (value < INT32_MIN || value > INT32_MAX) return invalid_result;
        values[index] = value;
    }
    heap_sort(values, count);
    std::int64_t best = values[0] + values[1] + values[2];
    std::int64_t best_difference = absolute_difference(target, best);
    for (std::size_t first = 0; first + 2 < count; ++first) {
        std::size_t left = first + 1, right = count - 1;
        while (left < right) {
            const std::int64_t sum = values[first] + values[left] + values[right];
            const std::int64_t difference = absolute_difference(target, sum);
            if (difference < best_difference || (difference == best_difference && sum < best)) {
                best = sum; best_difference = difference;
            }
            if (sum < target) ++left;
            else if (sum > target) --right;
            else return sum;
        }
    }
    return best;
}
