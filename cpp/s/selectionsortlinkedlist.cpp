/* Pointer-relinking selection sort represented by bounded node indices. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 64;
constexpr std::size_t max_input_length = 66;

void selection_sort_links(const std::int32_t values[max_count], std::int32_t next[max_count],
                          std::int32_t &head) noexcept
{
    std::int32_t minimum = head;
    std::int32_t current = next[minimum];
    std::int32_t previous = minimum;
    std::int32_t sorted_tail = -1;
    while (next[minimum] != -1) {
        while (current != -1) {
            if (values[current] < values[minimum]) {
                if (sorted_tail == -1) {
                    if (previous == minimum) {
                        head = current;
                        next[minimum] = next[current];
                        next[current] = previous;
                        minimum = current;
                        current = next[previous];
                    } else {
                        head = current;
                        next[previous] = next[current];
                        next[current] = minimum;
                        minimum = current;
                        current = next[previous];
                    }
                } else {
                    next[sorted_tail] = current;
                    next[previous] = next[current];
                    next[current] = minimum;
                    minimum = current;
                    current = next[previous];
                }
            } else {
                previous = next[previous];
                current = next[current];
            }
        }
        sorted_tail = minimum;
        minimum = next[minimum];
        previous = minimum;
        current = next[minimum];
    }
}

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) noexcept
{
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t selectionsortlinkedlist(const std::int64_t *input,
                                                  std::size_t length,
                                                  std::uint8_t *output,
                                                  std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t raw_count = input[0];
    if (raw_count < 1 || raw_count > static_cast<std::int64_t>(max_count) ||
        length != 1 + static_cast<std::size_t>(raw_count)) return -1;
    const std::size_t count = static_cast<std::size_t>(raw_count);
    std::int32_t values[max_count]{};
    std::int32_t next[max_count]{};
    for (std::size_t index = 0; index < count; ++index) {
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return -1;
        values[index] = static_cast<std::int32_t>(input[index + 1]);
        next[index] = index + 1 < count ? static_cast<std::int32_t>(index + 1) : -1;
    }
    const std::size_t byte_count = 4 * count;
    if (output == nullptr || output_capacity < byte_count) return -2;

    std::int32_t head = 0;
    selection_sort_links(values, next, head);
    std::int32_t node = head;
    for (std::size_t index = 0; index < count; ++index) {
        write_i32_le(output, 4 * index, values[node]);
        node = next[node];
    }
    return static_cast<std::int64_t>(byte_count);
}
