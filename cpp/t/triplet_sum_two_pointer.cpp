#include <cstddef>
#include <cstdint>

namespace {
void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
void sift_down(std::int64_t *values, std::size_t root, std::size_t end) {
    while (root < end / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) ++child;
        if (values[root] >= values[child]) break;
        const auto temporary = values[root]; values[root] = values[child]; values[child] = temporary;
        root = child;
    }
}
void heap_sort(std::int64_t *values, std::size_t length) {
    for (std::size_t start = length / 2; start > 0; --start) sift_down(values, start - 1, length);
    for (std::size_t end = length; end > 1; --end) {
        const auto temporary = values[0]; values[0] = values[end - 1]; values[end - 1] = temporary;
        sift_down(values, 0, end - 1);
    }
}
}

extern "C" std::int64_t triplet_sum_two_pointer(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t output_capacity) {
    constexpr std::size_t max_items = 1024;
    if (input == nullptr || length < 1 || length > max_items + 1 ||
        input[0] < -3000000 || input[0] > 3000000) return -1;
    const std::size_t item_count = length - 1;
    std::int64_t values[max_items];
    for (std::size_t index = 0; index < item_count; ++index) {
        if (input[index + 1] < -1000000 || input[index + 1] > 1000000) return -1;
        values[index] = input[index + 1];
    }
    if (output_capacity < 24 || output == nullptr) return -2;
    heap_sort(values, item_count);
    std::int64_t result[3] = {0, 0, 0};
    for (std::size_t first = 0; first + 2 < item_count; ++first) {
        std::size_t left = first + 1, right = item_count - 1;
        while (left < right) {
            const std::int64_t sum = values[first] + values[left] + values[right];
            if (sum == input[0]) {
                result[0] = values[first]; result[1] = values[left]; result[2] = values[right];
                first = item_count;
                break;
            }
            if (sum < input[0]) ++left; else --right;
        }
        if (first == item_count) break;
    }
    for (std::size_t index = 0; index < 3; ++index) put_i64_le(output, index * 8, result[index]);
    return 3;
}
