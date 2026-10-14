/* Binary-search-tree sort with iterative insertion and in-order traversal. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VALUES = 1024;
}

extern "C" void tree_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length > MAX_VALUES) return;
    std::int64_t keys[MAX_VALUES];
    std::size_t left[MAX_VALUES], right[MAX_VALUES], stack[MAX_VALUES];
    const std::size_t empty = length;
    std::size_t root = empty;
    for (std::size_t index = 0; index < length; ++index) {
        keys[index] = values[index];
        left[index] = right[index] = empty;
        if (root == empty) { root = index; continue; }
        std::size_t node = root;
        for (;;) {
            std::size_t *child = keys[index] < keys[node] ? &left[node] : &right[node];
            if (*child == empty) { *child = index; break; }
            node = *child;
        }
    }
    std::size_t current = root, stack_size = 0, output = 0;
    while (current != empty || stack_size > 0) {
        while (current != empty) { stack[stack_size++] = current; current = left[current]; }
        current = stack[--stack_size];
        values[output++] = keys[current];
        current = right[current];
    }
}
