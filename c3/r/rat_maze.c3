module rat_maze;

const usz MAX_N = 8;
const usz MAX_INPUT_WORDS = 1 + MAX_N * MAX_N;
const usz MAX_OUTPUT_BYTES = 4 * (1 + MAX_N * MAX_N);

fn bool search_path(int* input, int* path, int n, int row, int col) {
    int index = row * n + col;
    path[index] = 1;
    if (row == n - 1 && col == n - 1) return true;
    if (col + 1 < n && input[1 + index + 1] == 1 && search_path(input, path, n, row, col + 1)) return true;
    if (row + 1 < n && input[1 + index + n] == 1 && search_path(input, path, n, row + 1, col)) return true;
    path[index] = 0;
    return false;
}

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long rat_maze(int* input, usz length, char* output, usz capacity) @export("rat_maze") {
    if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
    int n_raw = input[0];
    if (n_raw < 1 || n_raw > 8) return -1;
    int n = n_raw, cells = n * n;
    if (length != (usz)(1 + cells) || input[1] != 1) return -1;
    for (int i = 0; i < cells; i += 1) if (input[1 + i] < 0 || input[1 + i] > 1) return -1;
    int[64] path;
    bool found = search_path(input, &path[0], n, 0, 0);
    usz word_count = found ? (usz)(1 + cells) : 1;
    usz bytes = word_count * 4;
    if (output == null || capacity < bytes) return -2;
    char[MAX_OUTPUT_BYTES] buffer;
    put_i32_le(&buffer[0], 0, found ? 1 : 0);
    if (found) for (int i = 0; i < cells; i += 1) put_i32_le(&buffer[0], (usz)(i + 1) * 4, path[i]);
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
