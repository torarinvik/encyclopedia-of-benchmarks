module rotting_oranges;

const int MAX_CELLS = 256;
const int MAX_INPUT_LENGTH = 259;
const long INVALID_RESULT = -9223372036854775808L;

fn long rotting_oranges(long* input, usz length) @export("rotting_oranges") {
    if (input == null) return length == 0 ? 0 : INVALID_RESULT;
    if (length == 0) return 0;
    if (length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] == 0) return input[1] == 0 && length == 2 ? 0 : INVALID_RESULT;
    if (input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 16) return INVALID_RESULT;

    usz rows = (usz)input[0], columns = (usz)input[1];
    usz cell_count = rows * columns;
    if (length != 2 + cell_count) return INVALID_RESULT;

    uint8[MAX_CELLS] cells = {};
    usz[MAX_CELLS] queue = {};
    ushort[MAX_CELLS] distance = {};
    usz head = 0, tail = 0, fresh = 0, rotted = 0;
    for (usz index = 0; index < cell_count; index++) {
        long value = input[2 + index];
        if (value < 0 || value > 2) return INVALID_RESULT;
        cells[index] = (uint8)value;
        if (value == 1) fresh++;
        else if (value == 2) { queue[tail] = index; tail++; }
    }
    if (columns == 0 || fresh == 0) return 0;

    ushort minutes = 0;
    while (head < tail) {
        usz index = queue[head];
        head++;
        usz row = index / columns, column = index % columns;
        ushort next_distance = distance[index] + 1;
        if (row > 0) {
            usz next = index - columns;
            if (cells[next] == 1) {
                cells[next] = 2; distance[next] = next_distance;
                if (next_distance > minutes) minutes = next_distance;
                rotted++; queue[tail] = next; tail++;
            }
        }
        if (column + 1 < columns) {
            usz next = index + 1;
            if (cells[next] == 1) {
                cells[next] = 2; distance[next] = next_distance;
                if (next_distance > minutes) minutes = next_distance;
                rotted++; queue[tail] = next; tail++;
            }
        }
        if (row + 1 < rows) {
            usz next = index + columns;
            if (cells[next] == 1) {
                cells[next] = 2; distance[next] = next_distance;
                if (next_distance > minutes) minutes = next_distance;
                rotted++; queue[tail] = next; tail++;
            }
        }
        if (column > 0) {
            usz next = index - 1;
            if (cells[next] == 1) {
                cells[next] = 2; distance[next] = next_distance;
                if (next_distance > minutes) minutes = next_distance;
                rotted++; queue[tail] = next; tail++;
            }
        }
    }
    return rotted == fresh ? (long)minutes : -1;
}
