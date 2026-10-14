/* Bounded unbalanced binary search tree with an index-based node pool. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t capacity = 256; constexpr std::int64_t invalid_result = -1; }

extern "C" std::int64_t binary_search_tree_benchmark(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1024 || length % 2 != 0) return invalid_result;
    const std::size_t operation_count = length / 2, none = capacity;
    std::int64_t key[capacity];
    std::size_t left[capacity], right[capacity], free_next[capacity];
    for (std::size_t i = 0; i < capacity; ++i) free_next[i] = i + 1;
    std::size_t free_head = 0, root = none, count = 0;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto opcode = values[2 * operation], payload = values[2 * operation + 1];
        std::int64_t observed = 0;
        if (opcode == 0) {
            if (payload < -1000000 || payload > 1000000) return invalid_result;
            auto parent = none, node = root;
            while (node != none && key[node] != payload) { parent = node; node = payload < key[node] ? left[node] : right[node]; }
            if (node == none) {
                if (count == capacity || free_head == none) return invalid_result;
                node = free_head; free_head = free_next[node];
                key[node] = payload; left[node] = right[node] = none;
                if (parent == none) root = node;
                else if (payload < key[parent]) left[parent] = node;
                else right[parent] = node;
                ++count; observed = 1;
            }
        } else if (opcode == 1) {
            if (payload < -1000000 || payload > 1000000) return invalid_result;
            auto parent = none, node = root;
            while (node != none && key[node] != payload) { parent = node; node = payload < key[node] ? left[node] : right[node]; }
            observed = static_cast<std::int64_t>(node != none);
            if (node != none) {
                if (left[node] != none && right[node] != none) {
                    auto pred_parent = node, pred = left[node];
                    while (right[pred] != none) { pred_parent = pred; pred = right[pred]; }
                    key[node] = key[pred]; parent = pred_parent; node = pred;
                }
                const auto child = left[node] != none ? left[node] : right[node];
                if (parent == none) root = child;
                else if (left[parent] == node) left[parent] = child;
                else right[parent] = child;
                free_next[node] = free_head; free_head = node; --count;
            }
        } else if (opcode == 2) {
            if (payload < -1000000 || payload > 1000000) return invalid_result;
            auto node = root;
            while (node != none && key[node] != payload) node = payload < key[node] ? left[node] : right[node];
            observed = static_cast<std::int64_t>(node != none);
        } else if (opcode == 3 || opcode == 4) {
            if (payload != 0 || root == none) return invalid_result;
            auto node = root;
            if (opcode == 3) { while (left[node] != none) node = left[node]; }
            else { while (right[node] != none) node = right[node]; }
            observed = key[node];
        } else if (opcode == 5) {
            if (payload != 0) return invalid_result;
            observed = static_cast<std::int64_t>(count);
        } else return invalid_result;
        checksum += (static_cast<std::int64_t>(operation) + 1) * (observed + 1000000);
    }
    std::size_t stack[capacity], top = 0, node = root, index = 0;
    while (node != none || top != 0) {
        while (node != none) { stack[top++] = node; node = left[node]; }
        node = stack[--top];
        checksum += (static_cast<std::int64_t>(operation_count + index) + 1) * (key[node] + 1000000);
        ++index; node = right[node];
    }
    return checksum;
}
