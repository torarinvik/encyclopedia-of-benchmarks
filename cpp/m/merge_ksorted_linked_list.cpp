#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_lists = 16;
constexpr std::size_t max_total_nodes = 128;
constexpr std::size_t max_input_length = 1 + max_lists + max_total_nodes;
constexpr std::size_t max_output_bytes = 4 * max_total_nodes;

struct HeapNode {
    std::int64_t value;
    std::size_t list_index;
    std::size_t node_index;
};

bool node_less(const HeapNode& left, const HeapNode& right) {
    if (left.value != right.value) return left.value < right.value;
    if (left.list_index != right.list_index) return left.list_index < right.list_index;
    return left.node_index < right.node_index;
}

void heap_push(std::array<HeapNode, max_lists>& heap, std::size_t& size, HeapNode node) {
    auto index = size++;
    while (index > 0) {
        const auto parent = (index - 1) / 2;
        if (!node_less(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

HeapNode heap_pop(std::array<HeapNode, max_lists>& heap, std::size_t& size) {
    const auto result = heap[0];
    const auto last = heap[--size];
    if (size > 0) {
        std::size_t index = 0;
        while (index < size / 2) {
            auto child = 2 * index + 1;
            if (child + 1 < size && node_less(heap[child + 1], heap[child])) ++child;
            if (!node_less(heap[child], last)) break;
            heap[index] = heap[child];
            index = child;
        }
        heap[index] = last;
    }
    return result;
}

void put_i32_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t merge_ksorted_linked_list(const std::int64_t* input,
                                                   std::size_t length,
                                                   std::uint8_t* output,
                                                   std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_lists)) return -1;
    const auto list_count = static_cast<std::size_t>(input[0]);
    std::array<std::size_t, max_lists> starts{};
    std::array<std::size_t, max_lists> lengths{};
    std::size_t position = 1, total_nodes = 0;
    for (std::size_t list = 0; list < list_count; ++list) {
        if (position >= length) return -1;
        const auto declared = input[position++];
        if (declared < 0 || static_cast<std::uint64_t>(declared) > max_total_nodes - total_nodes)
            return -1;
        const auto list_length = static_cast<std::size_t>(declared);
        if (list_length > length - position) return -1;
        starts[list] = position;
        lengths[list] = list_length;
        for (std::size_t node = 0; node < list_length; ++node) {
            const auto value = input[position + node];
            if (value < INT32_MIN || value > INT32_MAX ||
                (node > 0 && input[position + node - 1] > value)) return -1;
        }
        position += list_length;
        total_nodes += list_length;
    }
    if (position != length) return -1;

    const auto output_bytes = 4 * total_nodes;
    if (output == nullptr || capacity < output_bytes) return -2;

    std::array<HeapNode, max_lists> heap{};
    std::size_t heap_size = 0;
    for (std::size_t list = 0; list < list_count; ++list) {
        if (lengths[list] > 0)
            heap_push(heap, heap_size, HeapNode{input[starts[list]], list, 0});
    }

    std::array<std::uint8_t, max_output_bytes> buffer{};
    std::size_t written = 0;
    while (heap_size > 0) {
        const auto node = heap_pop(heap, heap_size);
        put_i32_le(buffer.data(), written, node.value);
        written += 4;
        const auto next_index = node.node_index + 1;
        if (next_index < lengths[node.list_index]) {
            heap_push(heap, heap_size, HeapNode{
                input[starts[node.list_index] + next_index], node.list_index, next_index
            });
        }
    }

    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = buffer[index];
    return static_cast<std::int64_t>(output_bytes);
}
