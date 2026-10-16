#include <cstddef>
#include <cstdint>
#include <climits>

namespace {
constexpr std::size_t max_initial = 64;
constexpr std::size_t max_operations = 128;
constexpr std::size_t max_heap_size = max_initial + max_operations;
constexpr std::int64_t invalid_result = -1;
constexpr std::int64_t capacity_result = -2;

struct MinMaxHeap {
    std::int32_t values[max_heap_size]{};
    std::size_t count = 0;
};

bool is_min_level(std::size_t index) {
    std::size_t value = index + 1;
    unsigned depth = 0;
    while (value > 1) { value >>= 1; ++depth; }
    return (depth & 1u) == 0;
}

void swap_values(MinMaxHeap &heap, std::size_t left, std::size_t right) {
    const auto temp = heap.values[left];
    heap.values[left] = heap.values[right];
    heap.values[right] = temp;
}

std::size_t best_descendant(const MinMaxHeap &heap, std::size_t index, bool find_min) {
    std::size_t best = max_heap_size;
    for (std::size_t offset = 0; offset < 6; ++offset) {
        const std::size_t candidate = offset < 2 ? 2 * index + 1 + offset : 4 * index + 1 + offset;
        if (candidate >= heap.count) break;
        if (best == max_heap_size || (find_min ? heap.values[candidate] < heap.values[best]
                                                : heap.values[candidate] > heap.values[best])) best = candidate;
    }
    return best;
}

void push_down(MinMaxHeap &heap, std::size_t index, bool find_min) {
    while (index < heap.count) {
        const auto best = best_descendant(heap, index, find_min);
        if (best == max_heap_size) return;
        const bool grandchild = best > 2 && (best - 3) / 4 == index;
        const bool improves = find_min ? heap.values[best] < heap.values[index]
                                       : heap.values[best] > heap.values[index];
        if (grandchild) {
            if (!improves) return;
            swap_values(heap, best, index);
            const auto parent = (best - 1) / 2;
            const bool violation = find_min ? heap.values[best] > heap.values[parent]
                                            : heap.values[best] < heap.values[parent];
            if (violation) swap_values(heap, best, parent);
            index = best;
        } else {
            if (improves) swap_values(heap, best, index);
            return;
        }
    }
}

void push_up_min(MinMaxHeap &heap, std::size_t index) {
    while (index > 2) {
        const auto grandparent = (index - 3) / 4;
        if (heap.values[index] >= heap.values[grandparent]) return;
        swap_values(heap, index, grandparent);
        index = grandparent;
    }
}

void push_up_max(MinMaxHeap &heap, std::size_t index) {
    while (index > 2) {
        const auto grandparent = (index - 3) / 4;
        if (heap.values[index] <= heap.values[grandparent]) return;
        swap_values(heap, index, grandparent);
        index = grandparent;
    }
}

void push_up(MinMaxHeap &heap, std::size_t index) {
    if (index == 0) return;
    const auto parent = (index - 1) / 2;
    if (is_min_level(index)) {
        if (heap.values[index] > heap.values[parent]) {
            swap_values(heap, index, parent);
            push_up_max(heap, parent);
        } else push_up_min(heap, index);
    } else if (heap.values[index] < heap.values[parent]) {
        swap_values(heap, index, parent);
        push_up_min(heap, parent);
    } else push_up_max(heap, index);
}

void add_value(MinMaxHeap &heap, std::int32_t value) {
    const auto index = heap.count++;
    heap.values[index] = value;
    push_up(heap, index);
}

std::size_t max_index(const MinMaxHeap &heap) {
    if (heap.count < 2) return 0;
    if (heap.count == 2) return 1;
    return heap.values[1] > heap.values[2] ? 1 : 2;
}

std::int32_t extract_at(MinMaxHeap &heap, std::size_t index) {
    const auto result = heap.values[index];
    --heap.count;
    if (index != heap.count) heap.values[index] = heap.values[heap.count];
    if (heap.count != 0 && index < heap.count) push_down(heap, index, is_min_level(index));
    return result;
}

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

void insertion_sort(std::int32_t *values, std::size_t count) {
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

extern "C" std::int64_t min_max_heap_double_ended(const std::int64_t *input, std::size_t length,
                                                      std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2) return invalid_result;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_initial)) return invalid_result;
    const auto initial_count = static_cast<std::size_t>(input[0]);
    if (length < initial_count + 2) return invalid_result;
    const auto operation_value = input[initial_count + 1];
    if (operation_value < 0 || operation_value > static_cast<std::int64_t>(max_operations)) return invalid_result;
    const auto operation_count = static_cast<std::size_t>(operation_value);
    if (length != initial_count + 2 + 2 * operation_count) return invalid_result;
    for (std::size_t index = 0; index < initial_count; ++index)
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return invalid_result;
    for (std::size_t index = 0; index < operation_count; ++index) {
        const auto opcode = input[initial_count + 2 + 2 * index];
        const auto argument = input[initial_count + 3 + 2 * index];
        if (opcode < 0 || opcode > 5) return invalid_result;
        if (opcode == 0) { if (argument < INT32_MIN || argument > INT32_MAX) return invalid_result; }
        else if (argument != 0) return invalid_result;
    }

    MinMaxHeap heap{};
    heap.count = initial_count;
    for (std::size_t index = 0; index < initial_count; ++index) heap.values[index] = static_cast<std::int32_t>(input[index + 1]);
    for (std::size_t index = initial_count / 2; index > 0; --index) push_down(heap, index - 1, is_min_level(index - 1));
    std::int64_t event_results[max_operations]{};
    std::size_t event_count = 0;
    for (std::size_t index = 0; index < operation_count; ++index) {
        const auto opcode = input[initial_count + 2 + 2 * index];
        const auto argument = static_cast<std::int32_t>(input[initial_count + 3 + 2 * index]);
        if (opcode == 0) add_value(heap, argument);
        else if (opcode == 1 || opcode == 3) {
            if (heap.count == 0) return invalid_result;
            event_results[event_count++] = opcode == 1 ? heap.values[0] : extract_at(heap, 0);
        } else if (opcode == 2 || opcode == 4) {
            if (heap.count == 0) return invalid_result;
            const auto position = max_index(heap);
            event_results[event_count++] = opcode == 2 ? heap.values[position] : extract_at(heap, position);
        } else event_results[event_count++] = static_cast<std::int64_t>(heap.count);
    }
    std::int32_t sorted[max_heap_size]{};
    for (std::size_t index = 0; index < heap.count; ++index) sorted[index] = heap.values[index];
    insertion_sort(sorted, heap.count);
    const auto required = (2 + event_count + heap.count) * 8;
    if (output == nullptr || capacity < required) return capacity_result;
    std::size_t offset = 0;
    write_i64_le(output, offset, static_cast<std::int64_t>(event_count)); offset += 8;
    for (std::size_t index = 0; index < event_count; ++index, offset += 8) write_i64_le(output, offset, event_results[index]);
    write_i64_le(output, offset, static_cast<std::int64_t>(heap.count)); offset += 8;
    for (std::size_t index = 0; index < heap.count; ++index, offset += 8) write_i64_le(output, offset, sorted[index]);
    return static_cast<std::int64_t>(required);
}
