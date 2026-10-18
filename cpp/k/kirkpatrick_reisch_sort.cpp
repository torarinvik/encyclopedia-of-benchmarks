#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxElements = 256;
constexpr std::size_t MaxBlocks = 17;
constexpr std::size_t MaxParseableInputLength = 258;
constexpr std::size_t MaxOutputBytes = 2048;

struct HeapNode {
    std::int64_t value;
    std::size_t block;
    std::size_t offset;
};

bool heap_less(const HeapNode& left, const HeapNode& right)
{
    if (left.value != right.value) return left.value < right.value;
    if (left.block != right.block) return left.block < right.block;
    return left.offset < right.offset;
}

void heap_push(std::array<HeapNode, MaxBlocks>& heap, std::size_t& length, HeapNode value)
{
    std::size_t position = length++;
    while (position > 0) {
        const std::size_t parent = (position - 1) / 2;
        if (!heap_less(value, heap[parent])) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}

HeapNode heap_pop(std::array<HeapNode, MaxBlocks>& heap, std::size_t& length)
{
    const HeapNode minimum = heap[0];
    const HeapNode last = heap[--length];
    if (length == 0) return minimum;
    std::size_t position = 0;
    while (position * 2 + 1 < length) {
        std::size_t child = position * 2 + 1;
        if (child + 1 < length && heap_less(heap[child + 1], heap[child])) ++child;
        if (!heap_less(heap[child], last)) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = last;
    return minimum;
}

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value)
{
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (unsigned int byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffu);
        bits >>= 8u;
    }
}
}

extern "C" std::int64_t kirkpatrick_reisch_sort(const std::int64_t* input, std::size_t input_length,
                                                 std::uint8_t* output, std::size_t capacity)
{
    if (input == nullptr || input_length < 1 || input_length > MaxParseableInputLength) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MaxElements)) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (input_length != count + 1) return -1;

    std::array<std::int64_t, MaxElements> blocks{};
    for (std::size_t index = 0; index < count; ++index) blocks[index] = input[index + 1];
    std::array<std::size_t, MaxBlocks> starts{};
    std::array<std::size_t, MaxBlocks> lengths{};
    std::size_t block_count = 0;
    std::size_t block_size = 1;
    if (count > 1) {
        while ((block_size + 1) * (block_size + 1) <= count) ++block_size;
        for (std::size_t start = 0; start < count; start += block_size) {
            const std::size_t length = count - start < block_size ? count - start : block_size;
            starts[block_count] = start;
            lengths[block_count] = length;
            ++block_count;
            for (std::size_t index = 1; index < length; ++index) {
                const std::int64_t value = blocks[start + index];
                std::size_t position = index;
                while (position > 0 && blocks[start + position - 1] > value) {
                    blocks[start + position] = blocks[start + position - 1];
                    --position;
                }
                blocks[start + position] = value;
            }
        }
    } else if (count == 1) {
        starts[0] = 0;
        lengths[0] = 1;
        block_count = 1;
    }

    std::array<std::int64_t, MaxElements> sorted{};
    std::size_t sorted_count = 0;
    std::array<HeapNode, MaxBlocks> heap{};
    std::size_t heap_length = 0;
    for (std::size_t block = 0; block < block_count; ++block)
        heap_push(heap, heap_length, {blocks[starts[block]], block, 0});
    while (heap_length > 0) {
        const HeapNode current = heap_pop(heap, heap_length);
        sorted[sorted_count++] = current.value;
        const std::size_t next = current.offset + 1;
        if (next < lengths[current.block])
            heap_push(heap, heap_length, {blocks[starts[current.block] + next], current.block, next});
    }

    const std::size_t output_bytes = sorted_count * 8;
    if (output_bytes > MaxOutputBytes) return -1;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < sorted_count; ++index)
        write_i64_le(output, index * 8, sorted[index]);
    return static_cast<std::int64_t>(output_bytes);
}
