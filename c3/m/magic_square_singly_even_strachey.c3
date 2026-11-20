module magic_square_singly_even_strachey;

const int MAX_ORDER = 30;
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

fn long magic_square_singly_even_strachey(long n) @export("magic_square_singly_even_strachey") {
    if (n < 6 || n > MAX_ORDER || n % 4 != 2) return -1;
    int order = (int)n;
    int half = order / 2;
    int k = half / 2;
    int block_size = half * half;
    int[900] odd;
    int[900] square;
    for (int i = 0; i < 900; i++) { odd[i] = 0; square[i] = 0; }

    int row = 0, column = half / 2;
    odd[row * MAX_ORDER + column] = 1;
    for (int value = 2; value <= block_size; value++) {
        int next_row = (row - 1 + half) % half;
        int next_column = (column + 1) % half;
        if (odd[next_row * MAX_ORDER + next_column] == 0) {
            row = next_row;
            column = next_column;
        } else {
            row = (row + 1) % half;
        }
        odd[row * MAX_ORDER + column] = value;
    }

    for (int r = 0; r < half; r++) {
        for (int c = 0; c < half; c++) {
            int value = odd[r * MAX_ORDER + c];
            square[r * MAX_ORDER + c] = value;
            square[r * MAX_ORDER + half + c] = value + 2 * block_size;
            square[(half + r) * MAX_ORDER + c] = value + 3 * block_size;
            square[(half + r) * MAX_ORDER + half + c] = value + block_size;
        }
    }

    for (int r = 0; r < half; r++) {
        for (int c = 0; c < k; c++) {
            int top = r * MAX_ORDER + c, bottom = (half + r) * MAX_ORDER + c;
            int saved = square[top]; square[top] = square[bottom]; square[bottom] = saved;
        }
        for (int c = half - (k - 1); c < half; c++) {
            int top = r * MAX_ORDER + half + c, bottom = (half + r) * MAX_ORDER + half + c;
            int saved = square[top]; square[top] = square[bottom]; square[bottom] = saved;
        }
    }
    {
        int top = k * MAX_ORDER, bottom = (half + k) * MAX_ORDER;
        int saved = square[top]; square[top] = square[bottom]; square[bottom] = saved;
    }
    {
        int top = k * MAX_ORDER + k, bottom = (half + k) * MAX_ORDER + k;
        int saved = square[top]; square[top] = square[bottom]; square[bottom] = saved;
    }

    ulong hash = hash_byte(FNV_OFFSET, (uint8)order);
    for (int r = 0; r < order; r++) for (int c = 0; c < order; c++) hash = hash_i32(hash, square[r * MAX_ORDER + c]);
    return (long)(hash & 0x7fffffffffffffff);
}
