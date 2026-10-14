/* Count minimum swaps needed to order a distinct-value array. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VALUES = 256;
bool position_less(const std::int64_t *keys, const std::size_t *order,
                   std::size_t left, std::size_t right) noexcept
{
    const std::size_t a = order[left], b = order[right];
    return keys[a] < keys[b] || (keys[a] == keys[b] && a < b);
}
void sift_down(const std::int64_t *keys, std::size_t *order,
               std::size_t heap_length, std::size_t root) noexcept
{
    while (root < heap_length / 2) {
        std::size_t child = root * 2 + 1;
        if (child + 1 < heap_length && position_less(keys, order, child, child + 1)) ++child;
        if (!position_less(keys, order, root, child)) break;
        const std::size_t temporary = order[root]; order[root] = order[child]; order[child] = temporary;
        root = child;
    }
}
} // namespace

extern "C" std::int64_t swap_sort(const std::int64_t *values, std::size_t length) noexcept
{
    if (length > MAX_VALUES) return -1;
    std::int64_t keys[MAX_VALUES];
    std::size_t order[MAX_VALUES];
    bool visited[MAX_VALUES] = {};
    for (std::size_t index = 0; index < length; ++index) { keys[index] = values[index]; order[index] = index; }
    for (std::size_t start = length / 2; start > 0;) { --start; sift_down(keys, order, length, start); }
    for (std::size_t end = length; end > 1;) {
        --end; const std::size_t temporary = order[0]; order[0] = order[end]; order[end] = temporary;
        sift_down(keys, order, end, 0);
    }
    for (std::size_t index = 1; index < length; ++index) if (keys[order[index - 1]] == keys[order[index]]) return -1;
    std::size_t swaps = 0;
    for (std::size_t start = 0; start < length; ++start) {
        if (visited[start]) continue;
        std::size_t node = start, cycle_length = 0;
        while (!visited[node]) { visited[node] = true; node = order[node]; ++cycle_length; }
        if (cycle_length > 0) swaps += cycle_length - 1;
    }
    return static_cast<std::int64_t>(swaps);
}
