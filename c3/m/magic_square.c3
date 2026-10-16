module magic_square;

const int MAX_ORDER = 31;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_byte(ulong hash, uint8 byte) {
    return (hash ^ (ulong)byte) * FNV_PRIME;
}

fn ulong hash_i32(ulong hash, int value) {
    uint bits = (uint)value;
    for (int shift = 0; shift < 32; shift += 8) hash = hash_byte(hash, (uint8)(bits >> shift));
    return hash;
}

fn long magic_square(long n) @export("magic_square") {
    if (n < 1 || n > MAX_ORDER || n % 2 == 0) return -1;
    int order = (int)n;
    int[961] square;
    for (int i = 0; i < 961; i++) square[i] = 0;
    int row = order / 2, column = order - 1;
    square[row * MAX_ORDER + column] = 1;
    for (int value = 2; value <= order * order; value++) {
        int next_row = (row - 1 + order) % order;
        int next_column = (column + 1) % order;
        if (square[next_row * MAX_ORDER + next_column] == 0) {
            row = next_row;
            column = next_column;
        } else {
            column = (column - 1 + order) % order;
        }
        square[row * MAX_ORDER + column] = value;
    }
    ulong hash = hash_byte(FNV_OFFSET, (uint8)order);
    for (int r = 0; r < order; r++) for (int c = 0; c < order; c++) hash = hash_i32(hash, square[r * MAX_ORDER + c]);
    return (long)(hash & 0x7fffffffffffffff);
}
