#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t max_initial = 64;
constexpr std::size_t max_operations = 128;
constexpr std::size_t max_keys = max_initial + max_operations;
constexpr std::size_t max_input = max_initial + 2 + 2 * max_operations;

struct IntervalHeap {
    std::int32_t keys[max_keys]{};
    std::size_t count = 0;
};

std::size_t high_index(const IntervalHeap &heap, std::size_t node) {
    const auto high = 2 * node + 1;
    return high < heap.count ? high : 2 * node;
}

void sift_up_low(IntervalHeap &heap, std::size_t node) {
    while (node > 0) {
        const auto parent = (node - 1) / 2;
        const auto low = 2 * node;
        const auto parent_low = 2 * parent;
        if (heap.keys[low] >= heap.keys[parent_low]) return;
        const auto temp = heap.keys[low];
        heap.keys[low] = heap.keys[parent_low];
        heap.keys[parent_low] = temp;
        node = parent;
    }
}

void sift_up_high(IntervalHeap &heap, std::size_t node) {
    while (node > 0) {
        const auto parent = (node - 1) / 2;
        const auto high = high_index(heap, node);
        const auto parent_high = high_index(heap, parent);
        if (heap.keys[high] <= heap.keys[parent_high]) return;
        const auto temp = heap.keys[high];
        heap.keys[high] = heap.keys[parent_high];
        heap.keys[parent_high] = temp;
        node = parent;
    }
}

void insert_key(IntervalHeap &heap, std::int32_t value) {
    const auto key_index = heap.count++;
    heap.keys[key_index] = value;
    const auto node = key_index / 2;
    if ((key_index & 1u) != 0 && heap.keys[key_index] < heap.keys[key_index - 1]) {
        const auto temp = heap.keys[key_index];
        heap.keys[key_index] = heap.keys[key_index - 1];
        heap.keys[key_index - 1] = temp;
    }
    sift_up_low(heap, node);
    sift_up_high(heap, node);
}

std::int32_t extract_min(IntervalHeap &heap) {
    const auto result = heap.keys[0];
    const auto last = heap.keys[--heap.count];
    if (heap.count == 0) return result;
    heap.keys[0] = last;
    std::size_t node = 0;
    for (;;) {
        const auto left = 2 * node + 1;
        if (2 * left >= heap.count) return result;
        const auto right = left + 1;
        auto child = left;
        if (2 * right < heap.count && heap.keys[2 * right] < heap.keys[2 * left]) child = right;
        const auto node_low = 2 * node;
        const auto child_low = 2 * child;
        if (heap.keys[child_low] >= heap.keys[node_low]) return result;
        const auto temp = heap.keys[node_low];
        heap.keys[node_low] = heap.keys[child_low];
        heap.keys[child_low] = temp;
        const auto child_high = high_index(heap, child);
        if (heap.keys[child_high] < heap.keys[child_low]) {
            const auto pair_temp = heap.keys[child_high];
            heap.keys[child_high] = heap.keys[child_low];
            heap.keys[child_low] = pair_temp;
        }
        node = child;
    }
}

std::int32_t extract_max(IntervalHeap &heap) {
    if (heap.count <= 2) return heap.keys[--heap.count];
    const auto result = heap.keys[1];
    heap.keys[1] = heap.keys[--heap.count];
    std::size_t node = 0;
    for (;;) {
        const auto left = 2 * node + 1;
        if (2 * left >= heap.count) return result;
        const auto right = left + 1;
        auto child = left;
        if (2 * right < heap.count && heap.keys[high_index(heap, left)] < heap.keys[high_index(heap, right)]) child = right;
        const auto node_high = high_index(heap, node);
        const auto child_high = high_index(heap, child);
        if (heap.keys[node_high] >= heap.keys[child_high]) return result;
        const auto temp = heap.keys[node_high];
        heap.keys[node_high] = heap.keys[child_high];
        heap.keys[child_high] = temp;
        const auto child_low = 2 * child;
        if (heap.keys[child_high] < heap.keys[child_low]) {
            const auto pair_temp = heap.keys[child_high];
            heap.keys[child_high] = heap.keys[child_low];
            heap.keys[child_low] = pair_temp;
        }
        node = child;
    }
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void sort_i32(std::int32_t *values, std::size_t count) {
    for (std::size_t index = 1; index < count; ++index) {
        const auto value = values[index];
        auto position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
}
}

extern "C" std::int64_t interval_heap_double_ended(const std::int64_t *input, std::size_t length,
                                                     std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_initial)) return -1;
    const auto initial_count = static_cast<std::size_t>(input[0]);
    if (length < initial_count + 2) return -1;
    if (input[initial_count + 1] < 0 || input[initial_count + 1] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto operation_count = static_cast<std::size_t>(input[initial_count + 1]);
    if (length != initial_count + 2 + 2 * operation_count) return -1;
    for (std::size_t index = 0; index < initial_count; ++index)
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return -1;
    for (std::size_t op = 0; op < operation_count; ++op) {
        const auto opcode = input[initial_count + 2 + 2 * op];
        const auto argument = input[initial_count + 3 + 2 * op];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) { if (argument < INT32_MIN || argument > INT32_MAX) return -1; }
        else if (argument != 0) return -1;
    }

    IntervalHeap heap{};
    for (std::size_t index = 0; index < initial_count; ++index) insert_key(heap, static_cast<std::int32_t>(input[index + 1]));
    std::int64_t events[max_operations]{};
    std::size_t event_count = 0;
    for (std::size_t op = 0; op < operation_count; ++op) {
        const auto opcode = input[initial_count + 2 + 2 * op];
        const auto argument = static_cast<std::int32_t>(input[initial_count + 3 + 2 * op]);
        if (opcode == 0) insert_key(heap, argument);
        else if (opcode == 1) { if (heap.count == 0) return -1; events[event_count++] = heap.keys[0]; }
        else if (opcode == 2) { if (heap.count == 0) return -1; events[event_count++] = heap.keys[high_index(heap, 0)]; }
        else if (opcode == 3) { if (heap.count == 0) return -1; events[event_count++] = extract_min(heap); }
        else if (opcode == 4) { if (heap.count == 0) return -1; events[event_count++] = extract_max(heap); }
        else events[event_count++] = static_cast<std::int64_t>(heap.count);
    }
    std::int32_t sorted[max_keys]{};
    for (std::size_t index = 0; index < heap.count; ++index) sorted[index] = heap.keys[index];
    sort_i32(sorted, heap.count);
    const auto required = (2 + event_count + heap.count) * 8;
    if (output == nullptr || capacity < required) return -2;
    std::size_t offset = 0;
    write_i64_le(output, offset, static_cast<std::int64_t>(event_count)); offset += 8;
    for (std::size_t index = 0; index < event_count; ++index, offset += 8) write_i64_le(output, offset, events[index]);
    write_i64_le(output, offset, static_cast<std::int64_t>(heap.count)); offset += 8;
    for (std::size_t index = 0; index < heap.count; ++index, offset += 8) write_i64_le(output, offset, sorted[index]);
    return static_cast<std::int64_t>(required);
}
