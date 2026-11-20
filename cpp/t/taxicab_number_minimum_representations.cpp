#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_root = 444;
constexpr std::size_t max_parseable_length = 2;

struct Node {
    std::int32_t sum;
    std::int32_t a;
    std::int32_t b;
};

bool less_node(const Node& left, const Node& right) noexcept {
    if (left.sum != right.sum) return left.sum < right.sum;
    if (left.a != right.a) return left.a < right.a;
    return left.b < right.b;
}

void push(std::array<Node, max_root>& heap, std::size_t& size, Node node) noexcept {
    std::size_t index = size++;
    while (index > 0) {
        const std::size_t parent = (index - 1) / 2;
        if (!less_node(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

Node pop(std::array<Node, max_root>& heap, std::size_t& size) noexcept {
    const Node result = heap[0];
    const Node last = heap[--size];
    if (size == 0) return result;
    std::size_t index = 0;
    while (2 * index + 1 < size) {
        std::size_t child = 2 * index + 1;
        if (child + 1 < size && less_node(heap[child + 1], heap[child])) ++child;
        if (!less_node(heap[child], last)) break;
        heap[index] = heap[child];
        index = child;
    }
    heap[index] = last;
    return result;
}

constexpr std::int32_t cube(std::int32_t value) noexcept {
    return value * value * value;
}

std::int64_t search(std::int32_t ways) noexcept {
    std::array<Node, max_root> heap{};
    std::size_t size = 0;
    for (std::int32_t a = 1; a <= static_cast<std::int32_t>(max_root); ++a) {
        const std::int32_t value = cube(a);
        push(heap, size, Node{2 * value, a, a});
    }
    while (size > 0) {
        const Node first = pop(heap, size);
        const std::int32_t total = first.sum;
        std::int32_t count = 1;
        if (first.b < static_cast<std::int32_t>(max_root)) {
            const auto next_b = first.b + 1;
            push(heap, size, Node{cube(first.a) + cube(next_b), first.a, next_b});
        }
        while (size > 0 && heap[0].sum == total) {
            const Node equal = pop(heap, size);
            ++count;
            if (equal.b < static_cast<std::int32_t>(max_root)) {
                const auto next_b = equal.b + 1;
                push(heap, size, Node{cube(equal.a) + cube(next_b), equal.a, next_b});
            }
        }
        if (count >= ways) return total;
    }
    return -1;
}
}

extern "C" std::int64_t taxicab_number_minimum_representations(
    const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    if (length != 1 || (input[0] != 2 && input[0] != 3)) return -1;
    return search(static_cast<std::int32_t>(input[0]));
}
