#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_requests = 64;
constexpr std::size_t max_output_values = 65;

void sort_ascending(std::array<std::int32_t, max_requests>& values, std::size_t count)
{
    for (std::size_t i = 1; i < count; ++i) {
        const auto value = values[i];
        std::size_t position = i;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
}

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value)
{
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t scan_scheduling(const std::int32_t* input, std::size_t length,
                                          std::uint8_t* output, std::size_t capacity)
{
    if (input == nullptr || length < 4 || length > 68) return -1;
    const auto disk_size = input[0], head = input[1], direction = input[2], request_count = input[3];
    if (disk_size < 1 || disk_size > 256 || head < 0 || head >= disk_size ||
        (direction != 0 && direction != 1) || request_count < 0 || request_count > static_cast<std::int32_t>(max_requests) ||
        length != 4 + static_cast<std::size_t>(request_count)) return -1;

    std::array<std::int32_t, max_requests> left{}, right{};
    std::size_t left_count = 0, right_count = 0;
    for (std::size_t i = 0; i < static_cast<std::size_t>(request_count); ++i) {
        const auto request = input[4 + i];
        if (request < 0 || request >= disk_size) return -1;
        if (request < head) left[left_count++] = request;
        else right[right_count++] = request;
    }
    sort_ascending(left, left_count);
    sort_ascending(right, right_count);

    std::array<std::int32_t, max_output_values> ordered{};
    std::size_t count = 0;
    if (request_count > 0) {
        if (direction == 1) {
            for (std::size_t i = 0; i < right_count; ++i) ordered[count++] = right[i];
            ordered[count++] = disk_size - 1;
            for (std::size_t i = left_count; i > 0; --i) ordered[count++] = left[i - 1];
        } else {
            for (std::size_t i = left_count; i > 0; --i) ordered[count++] = left[i - 1];
            ordered[count++] = 0;
            for (std::size_t i = 0; i < right_count; ++i) ordered[count++] = right[i];
        }
    }
    const std::size_t bytes = count * 4;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t i = 0; i < count; ++i) put_i32_le(output, i * 4, ordered[i]);
    return static_cast<std::int64_t>(bytes);
}
