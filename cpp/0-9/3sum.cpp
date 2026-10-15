// Return unique sorted zero-sum triplets using sort-and-two-pointers.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 257;
constexpr std::size_t bytes_per_triplet = 12;

void sift_down(std::int64_t *values, std::size_t root, std::size_t end) {
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

void store_i32_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

std::size_t enumerate_triplets(const std::int64_t *values, std::size_t length,
                               std::uint8_t *output, bool write_output) {
    std::size_t result_count = 0;
    for (std::size_t first = 0; first + 2 < length; ++first) {
        if (first != 0 && values[first] == values[first - 1]) continue;
        std::size_t left = first + 1, right = length - 1;
        while (left < right) {
            const auto sum = values[first] + values[left] + values[right];
            if (sum < 0) {
                ++left;
            } else if (sum > 0) {
                --right;
            } else {
                if (write_output) {
                    const auto offset = result_count * bytes_per_triplet;
                    store_i32_le(output, offset, values[first]);
                    store_i32_le(output, offset + 4, values[left]);
                    store_i32_le(output, offset + 8, values[right]);
                }
                ++result_count;
                ++left;
                --right;
                while (left < right && values[left] == values[left - 1]) ++left;
                while (left < right && values[right] == values[right + 1]) --right;
            }
        }
    }
    return result_count;
}
}

extern "C" std::int64_t three_sum(const std::int64_t *input, std::size_t length,
                                 std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_items || (length != 0 && input == nullptr)) return -1;
    std::int64_t values[max_items];
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] < -100000 || input[index] > 100000) return -1;
        values[index] = input[index];
    }
    heap_sort(values, length);

    const auto maximum_bytes = length < 2 ? 0 : (length * (length - 1) / 2) * bytes_per_triplet;
    if (output_capacity < maximum_bytes || output == nullptr) {
        const auto needed = enumerate_triplets(values, length, nullptr, false) * bytes_per_triplet;
        if (output_capacity < needed || (needed != 0 && output == nullptr)) return -2;
    }
    return static_cast<std::int64_t>(enumerate_triplets(values, length, output, output != nullptr));
}
