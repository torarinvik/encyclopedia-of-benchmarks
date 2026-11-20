#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 1024;
constexpr std::uint32_t none = static_cast<std::uint32_t>(max_items);
using NodeTable = std::array<std::uint32_t, max_items>;

bool pile_less(const std::int64_t* values, const NodeTable& pile_front,
               std::uint32_t left, std::uint32_t right) noexcept {
    const auto left_node = pile_front[left];
    const auto right_node = pile_front[right];
    if (values[left_node] != values[right_node]) return values[left_node] < values[right_node];
    return left < right;
}

void sift_down(const std::int64_t* values, const NodeTable& pile_front, NodeTable& heap,
               std::uint32_t heap_size, std::uint32_t position) noexcept {
    while (position * 2 + 1 < heap_size) {
        auto child = position * 2 + 1;
        if (child + 1 < heap_size
                && pile_less(values, pile_front, heap[child + 1], heap[child])) ++child;
        if (!pile_less(values, pile_front, heap[child], heap[position])) break;
        const auto temporary = heap[position];
        heap[position] = heap[child];
        heap[child] = temporary;
        position = child;
    }
}
}

extern "C" void unshuffle_sort(std::int64_t* values, std::int64_t* scratch,
                                std::size_t length) noexcept {
    if (values == nullptr || scratch == nullptr || length < 2 || length > max_items) return;

    NodeTable previous{}, next{}, pile_front{}, pile_back{}, heap{};
    std::uint32_t pile_count = 0;
    for (std::uint32_t node = 0; node < length; ++node) {
        previous[node] = none;
        next[node] = none;
        std::uint32_t pile = 0;
        while (pile < pile_count) {
            const auto front = pile_front[pile];
            const auto back = pile_back[pile];
            if (values[node] <= values[front]) {
                next[node] = front;
                previous[front] = node;
                pile_front[pile] = node;
                break;
            }
            if (values[node] >= values[back]) {
                previous[node] = back;
                next[back] = node;
                pile_back[pile] = node;
                break;
            }
            ++pile;
        }
        if (pile == pile_count) {
            pile_front[pile_count] = node;
            pile_back[pile_count] = node;
            ++pile_count;
        }
    }

    std::uint32_t heap_size = 0;
    for (std::uint32_t pile = 0; pile < pile_count; ++pile) {
        auto position = heap_size++;
        heap[position] = pile;
        while (position > 0) {
            const auto parent = (position - 1) / 2;
            if (!pile_less(values, pile_front, heap[position], heap[parent])) break;
            const auto temporary = heap[position];
            heap[position] = heap[parent];
            heap[parent] = temporary;
            position = parent;
        }
    }

    std::size_t output = 0;
    while (heap_size > 0) {
        const auto pile = heap[0];
        const auto node = pile_front[pile];
        scratch[output++] = values[node];
        const auto successor = next[node];
        if (successor != none) {
            previous[successor] = none;
            next[node] = none;
            pile_front[pile] = successor;
        } else {
            pile_front[pile] = none;
            pile_back[pile] = none;
            --heap_size;
            if (heap_size > 0) heap[0] = heap[heap_size];
        }
        if (heap_size > 0) sift_down(values, pile_front, heap, heap_size, 0);
    }
    for (std::size_t index = 0; index < length; ++index) values[index] = scratch[index];
}
