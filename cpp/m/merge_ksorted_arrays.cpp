#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_arrays = 16;
constexpr std::size_t max_total_values = 128;
constexpr std::size_t max_parseable_length = 1 + max_arrays + max_total_values + 1;
constexpr std::int64_t min_value = -1'000'000;
constexpr std::int64_t max_value = 1'000'000;
constexpr std::int64_t checksum_offset = 1'000'001;

struct HeapNode {
    std::int64_t value;
    std::size_t array_index;
    std::size_t element_index;
};

bool node_less(const HeapNode &left, const HeapNode &right)
{
    if (left.value != right.value) return left.value < right.value;
    if (left.array_index != right.array_index) return left.array_index < right.array_index;
    return left.element_index < right.element_index;
}

void heap_push(std::array<HeapNode, max_arrays> &heap, std::size_t &size, HeapNode node)
{
    std::size_t index = size++;
    while (index > 0) {
        const std::size_t parent = (index - 1) / 2;
        if (!node_less(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

HeapNode heap_pop(std::array<HeapNode, max_arrays> &heap, std::size_t &size)
{
    const HeapNode result = heap[0];
    const HeapNode last = heap[--size];
    if (size > 0) {
        std::size_t index = 0;
        while (index < size / 2) {
            std::size_t child = 2 * index + 1;
            if (child + 1 < size && node_less(heap[child + 1], heap[child])) ++child;
            if (!node_less(heap[child], last)) break;
            heap[index] = heap[child];
            index = child;
        }
        heap[index] = last;
    }
    return result;
}
}

extern "C" std::int64_t merge_ksorted_arrays(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(max_arrays)) return -1;
    const std::size_t array_count = static_cast<std::size_t>(values[0]);
    std::array<std::size_t, max_arrays> starts{}, lengths{};
    std::size_t position = 1, total_values = 0;
    for (std::size_t array = 0; array < array_count; ++array) {
        if (position >= length) return -1;
        const std::int64_t declared = values[position++];
        if (declared < 0 || static_cast<std::uint64_t>(declared) > max_total_values - total_values) return -1;
        const std::size_t array_length = static_cast<std::size_t>(declared);
        if (array_length > length - position) return -1;
        starts[array] = position;
        lengths[array] = array_length;
        for (std::size_t index = 0; index < array_length; ++index) {
            const std::int64_t value = values[position + index];
            if (value < min_value || value > max_value ||
                (index > 0 && values[position + index - 1] > value)) return -1;
        }
        position += array_length;
        total_values += array_length;
    }
    if (position != length) return -1;

    std::array<HeapNode, max_arrays> heap{};
    std::size_t heap_size = 0;
    for (std::size_t array = 0; array < array_count; ++array) {
        if (lengths[array] > 0) heap_push(heap, heap_size, {values[starts[array]], array, 0});
    }
    std::int64_t checksum = 0, merged_index = 0;
    while (heap_size > 0) {
        const HeapNode node = heap_pop(heap, heap_size);
        checksum += (merged_index + 1) * (node.value + checksum_offset);
        ++merged_index;
        const std::size_t next_index = node.element_index + 1;
        if (next_index < lengths[node.array_index]) {
            heap_push(heap, heap_size,
                      {values[starts[node.array_index] + next_index], node.array_index, next_index});
        }
    }
    return checksum;
}
