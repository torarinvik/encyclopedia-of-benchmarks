#include <cstddef>
#include <cstdint>

extern "C" std::int64_t minimum_operations_to_move_all_balls(const std::int64_t *boxes, std::size_t length,
                                                               std::uint8_t *output, std::size_t output_capacity) {
    if (length > 256 || (length != 0 && boxes == nullptr)) return -1;
    std::int64_t right_ones = 0;
    std::int64_t right_distance = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (boxes[index] != 0 && boxes[index] != 1) return -1;
        if (boxes[index] == 1) {
            ++right_ones;
            right_distance += static_cast<std::int64_t>(index);
        }
    }
    const std::size_t required_capacity = length * 2;
    if (output_capacity < required_capacity) return -2;
    std::int64_t left_ones = 0;
    std::int64_t left_distance = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (boxes[index] == 1) {
            --right_ones;
            ++left_ones;
        }
        const std::int64_t distance = left_distance + right_distance;
        output[2 * index] = static_cast<std::uint8_t>(distance & 0xff);
        output[2 * index + 1] = static_cast<std::uint8_t>((distance >> 8) & 0xff);
        right_distance -= right_ones;
        left_distance += left_ones;
    }
    return static_cast<std::int64_t>(length);
}
