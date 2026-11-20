module myers_ond_shortest_edit_script;

const usz MAX_SEQUENCE = 16;
const usz MAX_DISTANCE = 32;
const usz MAX_OUTPUT = 48;
const long OFFSET = 33;
const usz DIAGONALS = 67;

fn long build_script(long* input, uchar* output) {
    long n = input[0];
    long m = input[1];
    long* first = input + 2;
    long* second = first + n;
    int[DIAGONALS] frontier;
    int[MAX_DISTANCE + 1][DIAGONALS] trace;
    for (usz i = 0; i < DIAGONALS; i++) frontier[i] = -1;
    for (usz d = 0; d <= MAX_DISTANCE; d++)
        for (usz i = 0; i < DIAGONALS; i++) trace[d][i] = -1;
    frontier[OFFSET + 1] = 0;
    long found_d = -1;
    long found_k = 0;
    for (long d = 0; d <= n + m && found_d < 0; d++) {
        for (long k = -d; k <= d; k += 2) {
            usz slot = (usz)(OFFSET + k);
            long x;
            if (k == -d || (k != d && frontier[slot - 1] < frontier[slot + 1]))
                x = frontier[slot + 1];
            else
                x = frontier[slot - 1] + 1;
            long y = x - k;
            while (x < n && y < m && first[x] == second[y]) { x++; y++; }
            frontier[slot] = (int)x;
            trace[d][slot] = (int)x;
            if (x >= n && y >= m) { found_d = d; found_k = k; break; }
        }
    }

    uchar[MAX_DISTANCE] reverse_ops;
    uchar[MAX_DISTANCE] reverse_symbols;
    long path_length = 0;
    long x = n;
    long y = m;
    long k = found_k;
    for (long d = found_d; d > 0; d--) {
        usz slot = (usz)(OFFSET + k);
        long previous_k;
        long previous_x;
        long previous_y;
        long snake_x;
        long snake_y;
        if (k == -d || (k != d && trace[d - 1][slot - 1] < trace[d - 1][slot + 1])) {
            previous_k = k + 1;
            previous_x = trace[d - 1][(usz)(OFFSET + previous_k)];
            previous_y = previous_x - previous_k;
            snake_x = previous_x;
            snake_y = previous_y + 1;
            while (x > snake_x && y > snake_y) {
                reverse_ops[path_length] = 0; reverse_symbols[path_length] = 0; path_length++;
                x--; y--;
            }
            reverse_ops[path_length] = 2; reverse_symbols[path_length] = (uchar)second[previous_y]; path_length++;
        } else {
            previous_k = k - 1;
            previous_x = trace[d - 1][(usz)(OFFSET + previous_k)];
            previous_y = previous_x - previous_k;
            snake_x = previous_x + 1;
            snake_y = previous_y;
            while (x > snake_x && y > snake_y) {
                reverse_ops[path_length] = 0; reverse_symbols[path_length] = 0; path_length++;
                x--; y--;
            }
            reverse_ops[path_length] = 1; reverse_symbols[path_length] = 0; path_length++;
        }
        x = previous_x; y = previous_y; k = previous_k;
    }
    for (long i = 0; i < trace[0][OFFSET]; i++) {
        reverse_ops[path_length] = 0; reverse_symbols[path_length] = 0; path_length++;
    }
    long bytes = 0;
    for (long i = path_length; i > 0; i--) {
        long step = i - 1;
        output[bytes++] = reverse_ops[step];
        if (reverse_ops[step] == 2) output[bytes++] = reverse_symbols[step];
    }
    return bytes;
}

fn long myers_ond_shortest_edit_script(long* input, usz length, char* output, usz output_capacity)
    @export("myers_ond_shortest_edit_script")
{
    if (input == null || length < 2 || length > 2 + 2 * MAX_SEQUENCE) return -1;
    long n = input[0];
    long m = input[1];
    if (n < 0 || n > (long)MAX_SEQUENCE || m < 0 || m > (long)MAX_SEQUENCE) return -1;
    if (length != (usz)(2 + n + m)) return -1;
    for (usz i = 0; i < (usz)(n + m); i++)
        if (input[2 + i] < 0 || input[2 + i] > 255) return -1;
    if (output == null) return -2;
    uchar[MAX_OUTPUT] staged;
    long needed = build_script(input, &staged[0]);
    if (output_capacity < (usz)needed) return -2;
    for (long i = 0; i < needed; i++) output[i] = (char)staged[i];
    return needed;
}
