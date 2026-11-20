module crust_opposite_pole_selection;

const usz MAX_SAMPLES = 8, MAX_CELL_VERTICES = 8;
fn void put_i64(char* out, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) out[word * 8 + b] = (char)((bits >> (8 * b)) & 255);
}
fn bool same_point(long* a, long* b) { return a[0] == b[0] && a[1] == b[1] && a[2] == b[2]; }

fn long crust_opposite_pole_selection(long* input, usz length, char* output, usz capacity)
        @export("crust_opposite_pole_selection") {
    if (input == null || length < 1 || length > 226) return -1;
    long n0 = input[0];
    if (n0 < 1 || n0 > 8) return -1;
    usz n = (usz)n0, offset = 1;
    long[8][3] samples = {};
    long[8][2] answer = {};
    for (usz row = 0; row < n; row++) {
        if (offset + 4 > length) return -1;
        long[3] sample = {input[offset], input[offset + 1], input[offset + 2]};
        long count0 = input[offset + 3]; offset += 4;
        if (count0 < 1 || count0 > 8) return -1;
        usz count = (usz)count0;
        for (usz axis = 0; axis < 3; axis++) if (sample[axis] < -16 || sample[axis] > 16) return -1;
        for (usz j = 0; j < row; j++) if (same_point(&sample[0], &samples[j][0])) return -1;
        for (usz axis = 0; axis < 3; axis++) samples[row][axis] = sample[axis];
        if (offset + 3 * count > length) return -1;
        long[8][3] cell = {};
        for (usz v = 0; v < count; v++) {
            for (usz axis = 0; axis < 3; axis++) {
                cell[v][axis] = input[offset++];
                if (cell[v][axis] < -16 || cell[v][axis] > 16) return -1;
            }
            if (same_point(&sample[0], &cell[v][0])) return -1;
            for (usz j = 0; j < v; j++) if (same_point(&cell[v][0], &cell[j][0])) return -1;
        }
        usz positive = 0; long best = -1;
        for (usz v = 0; v < count; v++) {
            long distance = 0;
            for (usz axis = 0; axis < 3; axis++) { long delta = cell[v][axis] - sample[axis]; distance += delta * delta; }
            if (distance > best) { best = distance; positive = v; }
        }
        long[3] forward = {};
        for (usz axis = 0; axis < 3; axis++) forward[axis] = cell[positive][axis] - sample[axis];
        long negative = -1, negative_best = -1;
        for (usz v = 0; v < count; v++) {
            long distance = 0, projection = 0;
            for (usz axis = 0; axis < 3; axis++) {
                long delta = cell[v][axis] - sample[axis]; distance += delta * delta; projection += delta * forward[axis];
            }
            if (projection < 0 && distance > negative_best) { negative_best = distance; negative = (long)v; }
        }
        answer[row][0] = (long)positive; answer[row][1] = negative;
    }
    if (offset != length) return -1;
    usz bytes = 8 * (1 + 2 * n);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, n0); usz word = 1;
    for (usz row = 0; row < n; row++) { put_i64(output, word++, answer[row][0]); put_i64(output, word++, answer[row][1]); }
    return (long)bytes;
}
