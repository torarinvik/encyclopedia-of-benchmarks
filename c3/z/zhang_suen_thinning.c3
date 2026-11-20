module zhang_suen_thinning;

const long MAX_ROWS = 32;
const long MAX_COLUMNS = 32;
const usz MAX_CELLS = 1024;

fn bool zst_thin_phase(char* image, char* marked, usz rows, usz columns,
                       bool second_phase) {
    usz cells = rows * columns;
    for (usz index = 0; index < cells; index++) marked[index] = 0;
    bool changed = false;
    for (usz row = 1; row + 1 < rows; row++) {
        for (usz column = 1; column + 1 < columns; column++) {
            usz index = row * columns + column;
            if (image[index] == 0) continue;
            char p2 = image[index - columns];
            char p3 = image[index - columns + 1];
            char p4 = image[index + 1];
            char p5 = image[index + columns + 1];
            char p6 = image[index + columns];
            char p7 = image[index + columns - 1];
            char p8 = image[index - 1];
            char p9 = image[index - columns - 1];
            char[9] ring = {p2, p3, p4, p5, p6, p7, p8, p9, p2};
            uint black_neighbors = 0;
            uint transitions = 0;
            for (usz neighbor = 0; neighbor < 8; neighbor++) {
                black_neighbors += ring[neighbor];
                if (ring[neighbor] == 0 && ring[neighbor + 1] == 1) transitions++;
            }
            if (black_neighbors < 2 || black_neighbors > 6 || transitions != 1) continue;
            bool blocked;
            if (second_phase) {
                blocked = (p2 != 0 && p4 != 0 && p8 != 0) ||
                          (p2 != 0 && p6 != 0 && p8 != 0);
            } else {
                blocked = (p2 != 0 && p4 != 0 && p6 != 0) ||
                          (p4 != 0 && p6 != 0 && p8 != 0);
            }
            if (blocked) continue;
            marked[index] = 1;
            changed = true;
        }
    }
    if (changed) {
        for (usz index = 0; index < cells; index++) {
            if (marked[index] != 0) image[index] = 0;
        }
    }
    return changed;
}

fn long zhang_suen_thinning(long* input, usz length, char* output,
                            usz output_capacity) @export("zhang_suen_thinning") {
    if (input == null || length < 3 || length > 1027) return -1;
    long rows_value = input[0];
    long columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_ROWS ||
        columns_value < 1 || columns_value > MAX_COLUMNS) return -1;
    usz rows = (usz)rows_value;
    usz columns = (usz)columns_value;
    usz cells = rows * columns;
    if (length != 2 + cells) return -1;
    for (usz index = 0; index < cells; index++) {
        if (input[index + 2] != 0 && input[index + 2] != 1) return -1;
    }
    if (output == null || output_capacity < cells) return -2;

    char[MAX_CELLS] image = {};
    char[MAX_CELLS] marked = {};
    for (usz index = 0; index < cells; index++) image[index] = (char)input[index + 2];
    while (true) {
        bool first_changed = zst_thin_phase(&image[0], &marked[0], rows, columns, false);
        bool second_changed = zst_thin_phase(&image[0], &marked[0], rows, columns, true);
        if (!first_changed && !second_changed) break;
    }
    for (usz index = 0; index < cells; index++) output[index] = image[index];
    return (long)cells;
}
