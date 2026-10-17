#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 256;

std::int32_t read_i32_le(const std::uint8_t *buffer, std::size_t index)
{
    const std::size_t offset = index * 4;
    const std::uint32_t bits = static_cast<std::uint32_t>(buffer[offset])
        | (static_cast<std::uint32_t>(buffer[offset + 1]) << 8)
        | (static_cast<std::uint32_t>(buffer[offset + 2]) << 16)
        | (static_cast<std::uint32_t>(buffer[offset + 3]) << 24);
    return static_cast<std::int32_t>(bits);
}

void write_i32_le(std::uint8_t *buffer, std::size_t index, std::int32_t value)
{
    const auto bits = static_cast<std::uint32_t>(value);
    const std::size_t offset = index * 4;
    buffer[offset] = static_cast<std::uint8_t>(bits);
    buffer[offset + 1] = static_cast<std::uint8_t>(bits >> 8);
    buffer[offset + 2] = static_cast<std::uint8_t>(bits >> 16);
    buffer[offset + 3] = static_cast<std::uint8_t>(bits >> 24);
}

void merge(std::uint8_t *buffer, std::size_t start, std::size_t middle,
           std::size_t end, std::int32_t max_element)
{
    std::size_t i = start, j = middle + 1, k = start;
    while (i <= middle && j <= end) {
        const auto left = read_i32_le(buffer, i) % max_element;
        const auto right = read_i32_le(buffer, j) % max_element;
        const auto current = read_i32_le(buffer, k);
        if (left <= right) {
            write_i32_le(buffer, k++, current + left * max_element);
            ++i;
        } else {
            write_i32_le(buffer, k++, current + right * max_element);
            ++j;
        }
    }
    while (i <= middle) {
        const auto current = read_i32_le(buffer, k);
        const auto next = read_i32_le(buffer, i) % max_element;
        write_i32_le(buffer, k++, current + next * max_element);
        ++i;
    }
    while (j <= end) {
        const auto current = read_i32_le(buffer, k);
        const auto next = read_i32_le(buffer, j) % max_element;
        write_i32_le(buffer, k++, current + next * max_element);
        ++j;
    }
    for (std::size_t index = start; index <= end; ++index)
        write_i32_le(buffer, index, read_i32_le(buffer, index) / max_element);
}

void merge_sort(std::uint8_t *buffer, std::size_t start, std::size_t end,
                std::int32_t max_element)
{
    if (start >= end) return;
    const std::size_t middle = start + (end - start) / 2;
    merge_sort(buffer, start, middle, max_element);
    merge_sort(buffer, middle + 1, end, max_element);
    merge(buffer, start, middle, end, max_element);
}
} // namespace

extern "C" std::int64_t merge_sort_no_extra_space(const std::int32_t *values,
                                                   std::size_t length,
                                                   std::uint8_t *output,
                                                   std::size_t output_capacity)
{
    if (values == nullptr || length > max_length) return -1;
    std::int32_t max_value = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 32767) return -1;
        if (values[index] > max_value) max_value = values[index];
    }
    const std::size_t output_bytes = length * 4;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < length; ++index)
        write_i32_le(output, index, values[index]);
    if (length > 1) merge_sort(output, 0, length - 1, max_value + 1);
    return static_cast<std::int64_t>(output_bytes);
}
