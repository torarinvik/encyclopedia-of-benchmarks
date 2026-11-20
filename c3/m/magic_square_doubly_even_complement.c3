module magic_square_doubly_even_complement;

const int MIN_ORDER = 4;
const int MAX_ORDER = 64;
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

fn long magic_square_doubly_even_complement(long n) @export("magic_square_doubly_even_complement") {
    if (n < MIN_ORDER || n > MAX_ORDER || n % 4 != 0) return -1;
    int order = (int)n;
    int ceiling = order * order + 1;
    ulong hash = hash_byte(FNV_OFFSET, (uint8)order);

    for (int row = 0; row < order; row++) {
        for (int column = 0; column < order; column++) {
            int value = row * order + column + 1;
            int local_row = row % 4;
            int local_column = column % 4;
            if (local_row == local_column || local_row + local_column == 3) value = ceiling - value;
            hash = hash_i32(hash, value);
        }
    }
    return (long)(hash & 0x7fffffffffffffff);
}
