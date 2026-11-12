#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_ROWS = 8, MAX_COLS = 8, MAX_CELLS = 64, MAX_INPUT = 66 };

typedef struct { int64_t level; int cell; } heap_entry;

static bool entry_less(heap_entry a, heap_entry b) {
    return a.level < b.level || (a.level == b.level && a.cell < b.cell);
}

static void heap_push(heap_entry heap[MAX_CELLS], int *size, heap_entry item) {
    int position = (*size)++;
    while (position > 0) {
        const int parent = (position - 1) / 2;
        if (!entry_less(item, heap[parent])) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = item;
}

static heap_entry heap_pop(heap_entry heap[MAX_CELLS], int *size) {
    const heap_entry minimum = heap[0];
    const heap_entry last = heap[--(*size)];
    if (*size > 0) {
        int position = 0;
        while (2 * position + 1 < *size) {
            int child = 2 * position + 1;
            if (child + 1 < *size && entry_less(heap[child + 1], heap[child])) ++child;
            if (!entry_less(heap[child], last)) break;
            heap[position] = heap[child];
            position = child;
        }
        heap[position] = last;
    }
    return minimum;
}

int64_t trapping_rain_water_ii(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLS) return -1;
    const int rows = (int)input[0], cols = (int)input[1];
    if (length != (size_t)(2 + rows * cols)) return -1;
    int64_t heights[MAX_CELLS];
    for (int cell = 0; cell < rows * cols; ++cell) {
        const int64_t height = input[2 + cell];
        if (height < 0 || height > 1000) return -1;
        heights[cell] = height;
    }

    bool visited[MAX_CELLS] = {false};
    heap_entry heap[MAX_CELLS];
    int heap_size = 0;
    for (int row = 0; row < rows; ++row) for (int col = 0; col < cols; ++col) {
        if (row == 0 || row + 1 == rows || col == 0 || col + 1 == cols) {
            const int cell = row * cols + col;
            if (!visited[cell]) {
                visited[cell] = true;
                heap_push(heap, &heap_size, (heap_entry){heights[cell], cell});
            }
        }
    }

    static const int dr[4] = {-1, 1, 0, 0};
    static const int dc[4] = {0, 0, -1, 1};
    int64_t retained = 0;
    while (heap_size > 0) {
        const heap_entry current = heap_pop(heap, &heap_size);
        const int row = current.cell / cols, col = current.cell % cols;
        for (int direction = 0; direction < 4; ++direction) {
            const int nr = row + dr[direction], nc = col + dc[direction];
            if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
            const int neighbor = nr * cols + nc;
            if (visited[neighbor]) continue;
            visited[neighbor] = true;
            const int64_t next_level = heights[neighbor] > current.level ? heights[neighbor] : current.level;
            if (heights[neighbor] < current.level) retained += current.level - heights[neighbor];
            heap_push(heap, &heap_size, (heap_entry){next_level, neighbor});
        }
    }
    return retained;
}
