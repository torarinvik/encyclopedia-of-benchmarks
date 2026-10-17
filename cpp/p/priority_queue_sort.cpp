/* Priority-queue sort using a bounded binary min-heap. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_count = 128;
constexpr std::size_t max_input_length = 130;

void heap_push(std::int32_t heap[max_count], std::size_t &size, std::int32_t value) noexcept
{
    std::size_t child = size++;
    heap[child] = value;
    while (child > 0) {
        const std::size_t parent = (child - 1) / 2;
        if (heap[parent] <= heap[child]) break;
        const std::int32_t temporary = heap[parent];
        heap[parent] = heap[child];
        heap[child] = temporary;
        child = parent;
    }
}

std::int32_t heap_pop(std::int32_t heap[max_count], std::size_t &size) noexcept
{
    const std::int32_t minimum = heap[0];
    --size;
    if (size == 0) return minimum;
    heap[0] = heap[size];
    std::size_t parent = 0;
    for (;;) {
        const std::size_t left = 2 * parent + 1;
        if (left >= size) break;
        const std::size_t right = left + 1;
        const std::size_t smaller = right < size && heap[right] < heap[left] ? right : left;
        if (heap[parent] <= heap[smaller]) break;
        const std::int32_t temporary = heap[parent];
        heap[parent] = heap[smaller];
        heap[smaller] = temporary;
        parent = smaller;
    }
    return minimum;
}

void write_i32_le(std::uint8_t *output, std::size_t offset, std::int32_t value) noexcept
{
    const std::uint32_t bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t priority_queue_sort(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > static_cast<std::int64_t>(max_count) ||
        length != 1 + static_cast<std::size_t>(raw_count)) return -1;
    const std::size_t count = static_cast<std::size_t>(raw_count);
    for (std::size_t index = 0; index < count; ++index)
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return -1;
    const std::size_t byte_count = 4 * count;
    if (output == nullptr || output_capacity < byte_count) return -2;

    std::int32_t heap[max_count]{};
    std::size_t heap_size = 0;
    for (std::size_t index = 0; index < count; ++index)
        heap_push(heap, heap_size, static_cast<std::int32_t>(input[index + 1]));
    for (std::size_t index = 0; index < count; ++index)
        write_i32_le(output, 4 * index, heap_pop(heap, heap_size));
    return static_cast<std::int64_t>(byte_count);
}
