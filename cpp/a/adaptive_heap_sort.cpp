#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 1024;

bool node_less(const std::int64_t* values, std::size_t left, std::size_t right) noexcept {
    return values[left] < values[right]
        || (values[left] == values[right] && left < right);
}

void push_candidate(const std::int64_t* values, std::size_t* heap,
                    std::size_t& heap_length, std::size_t node) noexcept {
    auto position = heap_length++;
    heap[position] = node;
    while (position > 0) {
        const auto parent = (position - 1) / 2;
        if (!node_less(values, heap[position], heap[parent])) break;
        const auto temporary = heap[position];
        heap[position] = heap[parent];
        heap[parent] = temporary;
        position = parent;
    }
}

std::size_t pop_candidate(const std::int64_t* values, std::size_t* heap,
                          std::size_t& heap_length) noexcept {
    const auto minimum = heap[0];
    --heap_length;
    if (heap_length == 0) return minimum;

    heap[0] = heap[heap_length];
    std::size_t position = 0;
    while (position < heap_length / 2) {
        auto child = position * 2 + 1;
        if (child + 1 < heap_length && node_less(values, heap[child + 1], heap[child])) {
            ++child;
        }
        if (!node_less(values, heap[child], heap[position])) break;
        const auto temporary = heap[position];
        heap[position] = heap[child];
        heap[child] = temporary;
        position = child;
    }
    return minimum;
}
}

extern "C" void adaptive_heap_sort(std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_values) return;

    std::array<std::size_t, max_values> left{};
    std::array<std::size_t, max_values> right{};
    std::array<std::size_t, max_values> construction_stack{};
    std::array<std::size_t, max_values> candidate_heap{};
    std::array<std::int64_t, max_values> output{};

    std::size_t stack_length = 0;
    for (std::size_t index = 0; index < length; ++index) {
        left[index] = length;
        right[index] = length;
        auto last = length;
        while (stack_length > 0 && values[construction_stack[stack_length - 1]] > values[index]) {
            last = construction_stack[--stack_length];
        }
        if (stack_length > 0) right[construction_stack[stack_length - 1]] = index;
        if (last < length) left[index] = last;
        construction_stack[stack_length++] = index;
    }

    std::size_t heap_length = 0;
    push_candidate(values, candidate_heap.data(), heap_length, construction_stack[0]);
    for (std::size_t output_index = 0; output_index < length; ++output_index) {
        const auto node = pop_candidate(values, candidate_heap.data(), heap_length);
        output[output_index] = values[node];
        if (left[node] < length) {
            push_candidate(values, candidate_heap.data(), heap_length, left[node]);
        }
        if (right[node] < length) {
            push_candidate(values, candidate_heap.data(), heap_length, right[node]);
        }
    }
    for (std::size_t index = 0; index < length; ++index) values[index] = output[index];
}
