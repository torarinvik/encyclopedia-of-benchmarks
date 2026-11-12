module trapping_rain_water_ii;

const usz MAX_ROWS = 8;
const usz MAX_COLS = 8;
const usz MAX_CELLS = 64;
const usz MAX_INPUT = 66;

fn void heap_push(long* heap, usz* size, long key) {
    usz position = (*size)++;
    while (position > 0) {
        usz parent = (position - 1) / 2;
        if (heap[parent] <= key) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = key;
}

fn long heap_pop(long* heap, usz* size) {
    long minimum = heap[0];
    long last = heap[--(*size)];
    if (*size > 0) {
        usz position = 0;
        while (2 * position + 1 < *size) {
            usz child = 2 * position + 1;
            if (child + 1 < *size && heap[child + 1] < heap[child]) child++;
            if (heap[child] >= last) break;
            heap[position] = heap[child];
            position = child;
        }
        heap[position] = last;
    }
    return minimum;
}

fn long trapping_rain_water_ii(long* input, usz length) @export("trapping_rain_water_ii") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long r0 = input[0], c0 = input[1];
    if (r0 < 1 || r0 > 8 || c0 < 1 || c0 > 8) return -1;
    usz rows = (usz)r0, cols = (usz)c0;
    if (length != 2 + rows * cols) return -1;
    long[MAX_CELLS] heights = {};
    for (usz cell = 0; cell < rows * cols; cell++) {
        long height = input[2 + cell];
        if (height < 0 || height > 1000) return -1;
        heights[cell] = height;
    }

    bool[MAX_CELLS] visited = {};
    long[MAX_CELLS] heap = {};
    usz heap_size = 0;
    for (usz row = 0; row < rows; row++) for (usz col = 0; col < cols; col++) {
        if (row == 0 || row + 1 == rows || col == 0 || col + 1 == cols) {
            usz cell = row * cols + col;
            if (!visited[cell]) {
                visited[cell] = true;
                heap_push(&heap[0], &heap_size, heights[cell] * 64 + (long)cell);
            }
        }
    }

    int[4] dr = {-1, 1, 0, 0};
    int[4] dc = {0, 0, -1, 1};
    long retained = 0;
    while (heap_size > 0) {
        long key = heap_pop(&heap[0], &heap_size);
        long level = key / 64;
        usz cell = (usz)(key % 64);
        usz row = cell / cols, col = cell % cols;
        for (usz direction = 0; direction < 4; direction++) {
            int nr = (int)row + dr[direction], nc = (int)col + dc[direction];
            if (nr < 0 || nr >= (int)rows || nc < 0 || nc >= (int)cols) continue;
            usz neighbor = (usz)nr * cols + (usz)nc;
            if (visited[neighbor]) continue;
            visited[neighbor] = true;
            long height = heights[neighbor];
            if (height < level) retained += level - height;
            long next_level = height > level ? height : level;
            heap_push(&heap[0], &heap_size, next_level * 64 + (long)neighbor);
        }
    }
    return retained;
}
