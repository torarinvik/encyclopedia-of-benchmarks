module bidirectional_breadth_first_search;

const int MAX_DIMENSION = 8;
const int MAX_CELLS = MAX_DIMENSION * MAX_DIMENSION;
const int MAX_INPUT_LENGTH = 5 + MAX_CELLS;
const int MAX_OUTPUT_VALUES = 1 + MAX_CELLS;

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long bidirectional_breadth_first_search(long* input, usz length, char* output, usz capacity) @export("bidirectional_breadth_first_search") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    long rows_value = input[0], cols_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION || cols_value < 1 || cols_value > MAX_DIMENSION) return -1;
    int rows = (int)rows_value, cols = (int)cols_value, cells = rows * cols;
    long start_value = input[2], goal_value = input[3], blocked_count_value = input[4];
    if (start_value < 0 || start_value >= cells || goal_value < 0 || goal_value >= cells || blocked_count_value < 0 || blocked_count_value > cells) return -1;
    usz blocked_count = (usz)blocked_count_value;
    if (length != 5 + blocked_count) return -1;

    bool blocked[MAX_CELLS] = {};
    for (usz index = 0; index < blocked_count; index++) {
        long value = input[5 + index];
        if (value < 0 || value >= cells || blocked[(int)value]) return -1;
        blocked[(int)value] = true;
    }
    int start = (int)start_value, goal = (int)goal_value;
    if (blocked[start] || blocked[goal]) return -1;

    long distance[2 * MAX_CELLS], parent[2 * MAX_CELLS];
    usz queue[2 * MAX_CELLS];
    usz head[2] = {0, 0}, tail[2] = {1, 1};
    for (int index = 0; index < 2 * MAX_CELLS; index++) { distance[index] = -1; parent[index] = -1; }
    distance[start] = 0;
    distance[MAX_CELLS + goal] = 0;
    queue[0] = (usz)start;
    queue[MAX_CELLS] = (usz)goal;
    long meeting = start == goal ? (long)start : -1;
    while (meeting < 0 && head[0] < tail[0] && head[1] < tail[1]) {
      for (int side = 0; side < 2; side++) {
        if (meeting >= 0) break;
        usz layer_end = tail[side];
        while (head[side] < layer_end) {
            int node = (int)queue[side * MAX_CELLS + head[side]++];
            int row = node / cols, col = node % cols;
            for (int direction = 0; direction < 4; direction++) {
                int neighbor = -1;
                if (direction == 0 && row > 0) neighbor = node - cols;
                else if (direction == 1 && col > 0) neighbor = node - 1;
                else if (direction == 2 && row + 1 < rows) neighbor = node + cols;
                else if (direction == 3 && col + 1 < cols) neighbor = node + 1;
                if (neighbor < 0 || blocked[neighbor] || distance[side * MAX_CELLS + neighbor] >= 0) continue;
                distance[side * MAX_CELLS + neighbor] = distance[side * MAX_CELLS + node] + 1;
                parent[side * MAX_CELLS + neighbor] = node;
                queue[side * MAX_CELLS + tail[side]++] = (usz)neighbor;
                if (distance[(1 - side) * MAX_CELLS + neighbor] >= 0) { meeting = neighbor; break; }
            }
            if (meeting >= 0) break;
        }
      }
    }
    long encoded[MAX_OUTPUT_VALUES];
    usz value_count = 1;
    if (meeting < 0) encoded[0] = 0;
    else {
        usz reverse_path[MAX_CELLS], prefix_count = 0, path_count = 0;
        long current = meeting;
        while (current >= 0) {
            reverse_path[prefix_count++] = (usz)current;
            if (current == start) break;
            current = parent[current];
        }
        for (usz index = 0; index < prefix_count; index++) encoded[1 + path_count++] = (long)reverse_path[prefix_count - 1 - index];
        current = parent[MAX_CELLS + meeting];
        while (current >= 0) { encoded[1 + path_count++] = current; current = parent[MAX_CELLS + current]; }
        encoded[0] = (long)path_count;
        value_count += path_count;
    }
    usz required = value_count * 8;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < value_count; index++) put_i64(output, index * 8, encoded[index]);
    return (long)required;
}
