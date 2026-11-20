module forest_fire_synchronous_stochastic_ca;

const usz MAX_CELLS = 64;
const usz MAX_INPUT = 1095;

fn void put_word(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[word * 8 + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long forest_fire_synchronous_stochastic_ca(long* input, usz length, char* output,
                                                usz capacity) @export("forest_fire_synchronous_stochastic_ca") {
    if (input == null || length < 6 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8 ||
        input[2] < 0 || input[2] > 8 || input[3] != 10000 ||
        input[4] < 0 || input[4] > 10000 || input[5] < 0 || input[5] > 10000) return -1;
    usz rows = (usz)input[0], cols = (usz)input[1], steps = (usz)input[2];
    usz cells = rows * cols;
    if (length != 6 + cells + 2 * steps * cells) return -1;
    for (usz i = 0; i < cells; i += 1) if (input[6 + i] < 0 || input[6 + i] > 2) return -1;
    for (usz row = 0; row < rows; row += 1) for (usz col = 0; col < cols; col += 1)
        if ((row == 0 || row + 1 == rows || col == 0 || col + 1 == cols) && input[6 + row * cols + col] != 0) return -1;
    usz tape = 6 + cells;
    for (usz i = 0; i < 2 * steps * cells; i += 1)
        if (input[tape + i] < 0 || input[tape + i] >= 10000) return -1;
    usz bytes = (1 + 3 * steps + cells) * 8;
    if (output == null || capacity < bytes) return -2;

    char[MAX_CELLS] current = {};
    char[MAX_CELLS] next = {};
    for (usz i = 0; i < cells; i += 1) current[i] = (char)input[6 + i];
    put_word(output, 0, (long)steps);
    for (usz tick = 0; tick < steps; tick += 1) {
        for (usz row = 0; row < rows; row += 1) for (usz col = 0; col < cols; col += 1) {
            usz site = row * cols + col;
            if (row == 0 || row + 1 == rows || col == 0 || col + 1 == cols) { next[site] = 0; continue; }
            if (current[site] == 2) { next[site] = 0; continue; }
            if (current[site] == 0) {
                next[site] = input[tape + tick * cells + site] < input[4] ? 1 : 0;
                continue;
            }
            bool near_fire = false;
            usz r0 = row > 0 ? row - 1 : 0;
            usz r1 = row + 1 < rows ? row + 1 : row;
            usz c0 = col > 0 ? col - 1 : 0;
            usz c1 = col + 1 < cols ? col + 1 : col;
            for (usz r = r0; r <= r1; r += 1) for (usz c = c0; c <= c1; c += 1)
                if ((r != row || c != col) && current[r * cols + c] == 2) near_fire = true;
            long strike = input[tape + steps * cells + tick * cells + site];
            next[site] = near_fire || strike < input[5] ? 2 : 1;
        }
        long[3] totals = {};
        for (usz i = 0; i < cells; i += 1) totals[(usz)next[i]] += 1;
        usz base = 1 + 3 * tick;
        for (usz state = 0; state < 3; state += 1) put_word(output, base + state, totals[state]);
        for (usz i = 0; i < cells; i += 1) current[i] = next[i];
    }
    usz final_base = 1 + 3 * steps;
    for (usz i = 0; i < cells; i += 1) put_word(output, final_base + i, (long)current[i]);
    return (long)bytes;
}
