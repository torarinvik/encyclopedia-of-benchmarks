#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_rows = 8, max_cols = 8, max_cells = 64, max_input = 66;
struct Entry { std::int64_t level; int cell; };
bool less_entry(Entry a, Entry b) { return a.level < b.level || (a.level == b.level && a.cell < b.cell); }
void push(std::array<Entry, max_cells>& heap, int& size, Entry item) {
    int position = size++;
    while (position > 0) {
        const int parent = (position - 1) / 2;
        if (!less_entry(item, heap[parent])) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = item;
}
Entry pop(std::array<Entry, max_cells>& heap, int& size) {
    const Entry minimum = heap[0], last = heap[--size];
    if (size > 0) {
        int position = 0;
        while (2 * position + 1 < size) {
            int child = 2 * position + 1;
            if (child + 1 < size && less_entry(heap[child + 1], heap[child])) ++child;
            if (!less_entry(heap[child], last)) break;
            heap[position] = heap[child];
            position = child;
        }
        heap[position] = last;
    }
    return minimum;
}
}

extern "C" std::int64_t trapping_rain_water_ii(const std::int64_t* input, std::size_t length) noexcept {
    if (!input || length < 2 || length > max_input) return -1;
    if (input[0] < 1 || input[0] > max_rows || input[1] < 1 || input[1] > max_cols) return -1;
    const int rows = static_cast<int>(input[0]), cols = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + rows * cols)) return -1;
    std::array<std::int64_t, max_cells> heights{};
    for (int cell = 0; cell < rows * cols; ++cell) {
        const auto height = input[2 + cell];
        if (height < 0 || height > 1000) return -1;
        heights[cell] = height;
    }

    std::array<bool, max_cells> visited{};
    std::array<Entry, max_cells> heap{};
    int heap_size = 0;
    for (int row = 0; row < rows; ++row) for (int col = 0; col < cols; ++col) {
        if (row == 0 || row + 1 == rows || col == 0 || col + 1 == cols) {
            const int cell = row * cols + col;
            if (!visited[cell]) { visited[cell] = true; push(heap, heap_size, {heights[cell], cell}); }
        }
    }

    constexpr int dr[4] = {-1, 1, 0, 0};
    constexpr int dc[4] = {0, 0, -1, 1};
    std::int64_t retained = 0;
    while (heap_size > 0) {
        const Entry current = pop(heap, heap_size);
        const int row = current.cell / cols, col = current.cell % cols;
        for (int direction = 0; direction < 4; ++direction) {
            const int nr = row + dr[direction], nc = col + dc[direction];
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
            const int neighbor = nr * cols + nc;
            if (visited[neighbor]) continue;
            visited[neighbor] = true;
            const auto height = heights[neighbor];
            if (height < current.level) retained += current.level - height;
            push(heap, heap_size, {height > current.level ? height : current.level, neighbor});
        }
    }
    return retained;
}
