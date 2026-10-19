module stanford_queens;

const long MIN_RUNS = 1;
const long MAX_RUNS = 100;
const int SOLVE_REPETITIONS = 50;
const usz MAX_OUTPUT_BYTES = 292;

fn bool try_queens(int row, int* columns, int* diagonal_sum, int* diagonal_diff, int* positions) {
    int j = 0;
    bool found = false;
    while (!found && j != 8) {
        j++;
        found = false;
        if (columns[j] != 0 && diagonal_sum[row + j] != 0 && diagonal_diff[row - j + 7] != 0) {
            positions[row] = j;
            columns[j] = 0;
            diagonal_sum[row + j] = 0;
            diagonal_diff[row - j + 7] = 0;
            if (row < 8) {
                found = try_queens(row + 1, columns, diagonal_sum, diagonal_diff, positions);
                if (!found) {
                    columns[j] = 1;
                    diagonal_sum[row + j] = 1;
                    diagonal_diff[row - j + 7] = 1;
                }
            } else {
                found = true;
            }
        }
    }
    return found;
}

fn bool doit() {
    int[9] a;
    int[17] b;
    int[15] c;
    int[9] x;
    for (int i = -7; i <= 16; ++i) {
        if (i >= 1 && i <= 8) a[i] = 1;
        if (i >= 2) b[i] = 1;
        if (i <= 7) c[i + 7] = 1;
    }
    return try_queens(1, &a[0], &b[0], &c[0], &x[0]);
}

fn void append_text(char* buffer, usz* used, const char* text) {
    while (*text != '\0') {
        buffer[*used] = *text;
        *used = *used + 1;
        text++;
    }
}

fn void append_integer(char* buffer, usz* used, int value) {
    int remaining = value;
    char[12] reverse;
    usz count = 0;
    do {
        reverse[count++] = (char)('0' + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    while (count > 0) {
        count--;
        buffer[*used] = reverse[count];
        *used = *used + 1;
    }
}

fn long stanford_queens(long runs, char* output, usz output_capacity)
    @export("stanford_queens") {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == null) return -2;
    char[MAX_OUTPUT_BYTES] staged;
    usz used = 0;
    for (int run = 0; run < (int)runs; ++run) {
        for (int repetition = 0; repetition < SOLVE_REPETITIONS; ++repetition) {
            if (!doit()) append_text(&staged[0], &used, " Error in Queens.\n");
        }
        append_integer(&staged[0], &used, run + 1);
        append_text(&staged[0], &used, "\n");
    }
    if (output_capacity < used) return -2;
    for (usz index = 0; index < used; ++index) output[index] = staged[index];
    return (long)used;
}
