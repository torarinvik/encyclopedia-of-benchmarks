module max_area_of_island;

const usz MAX_ROWS = 16;
const usz MAX_COLUMNS = 16;
const usz MAX_CELLS = MAX_ROWS * MAX_COLUMNS;

// Return the largest four-connected component of cells equal to one.
fn long max_area_of_island(long* input, usz length) @export("max_area_of_island") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > (long)MAX_ROWS ||
        input[1] < 0 || input[1] > (long)MAX_COLUMNS) return -1;
    usz rows = (usz)input[0];
    usz columns = (usz)input[1];
    usz cells = rows * columns;
    if (length != cells + 2) return -1;
    for (usz i = 0; i < cells; i++) {
        if (input[2 + i] != 0 && input[2 + i] != 1) return -1;
    }

    bool[MAX_CELLS] visited = {false};
    usz[MAX_CELLS] stack;
    usz maximum_area = 0;
    for (usz start = 0; start < cells; start++) {
        if (input[2 + start] == 0 || visited[start]) continue;
        usz top = 0;
        usz area = 0;
        visited[start] = true;
        stack[top++] = start;
        while (top > 0) {
            usz current = stack[--top];
            area++;
            usz row = current / columns;
            usz column = current % columns;
            usz neighbor;
            if (row > 0) {
                neighbor = current - columns;
                if (!visited[neighbor] && input[2 + neighbor] == 1) { visited[neighbor] = true; stack[top++] = neighbor; }
            }
            if (row + 1 < rows) {
                neighbor = current + columns;
                if (!visited[neighbor] && input[2 + neighbor] == 1) { visited[neighbor] = true; stack[top++] = neighbor; }
            }
            if (column > 0) {
                neighbor = current - 1;
                if (!visited[neighbor] && input[2 + neighbor] == 1) { visited[neighbor] = true; stack[top++] = neighbor; }
            }
            if (column + 1 < columns) {
                neighbor = current + 1;
                if (!visited[neighbor] && input[2 + neighbor] == 1) { visited[neighbor] = true; stack[top++] = neighbor; }
            }
        }
        if (area > maximum_area) maximum_area = area;
    }
    return (long)maximum_area;
}
