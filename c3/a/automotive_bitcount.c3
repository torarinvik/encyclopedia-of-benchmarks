module automotive_bitcount;

const long MAX_ITERATIONS = 1125000;
const int[16] NIBBLE_BITS = {0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4};
const long[7] INITIAL_SEEDS = {16839,18985,21520,3905,10113,8672,21285};

fn int count_kernighan(uint value) {
    int count = 0;
    while (value != 0) {
        value &= value - 1;
        count++;
    }
    return count;
}

fn int count_parallel(uint value) {
    value = ((value & 0xAAAAAAAA) >> 1) + (value & 0x55555555);
    value = ((value & 0xCCCCCCCC) >> 2) + (value & 0x33333333);
    value = ((value & 0xF0F0F0F0) >> 4) + (value & 0x0F0F0F0F);
    value = ((value & 0xFF00FF00) >> 8) + (value & 0x00FF00FF);
    value = ((value & 0xFFFF0000) >> 16) + (value & 0x0000FFFF);
    return (int)value;
}

fn int count_recursive_nybbles(uint value) {
    int count = NIBBLE_BITS[(usz)(value & 0xF)];
    return (value >> 4) == 0 ? count : count + count_recursive_nybbles(value >> 4);
}

fn int count_fixed_nybbles(uint value) {
    int count = 0;
    for (uint shift = 0; shift < 32; shift += 4) count += NIBBLE_BITS[(usz)((value >> shift) & 0xF)];
    return count;
}

fn int count_byte(uint value) {
    return NIBBLE_BITS[(usz)(value & 0xF)] + NIBBLE_BITS[(usz)((value >> 4) & 0xF)];
}

fn int count_bw_bytes(uint value) {
    return count_byte(value) + count_byte(value >> 8) + count_byte(value >> 24) + count_byte(value >> 16);
}

fn int count_ar_bytes(uint value) {
    int count = 0;
    for (uint index = 0; index < 4; index++) count += count_byte(value >> (index * 8));
    return count;
}

fn int count_shift_test(uint value) {
    int count = 0;
    uint bit = 0;
    while (bit < 64 && value != 0) {
        count += (int)(value & 1);
        value >>= 1;
        bit++;
    }
    return count;
}

fn int count_selected(usz algorithm, uint value) {
    if (algorithm == 0) return count_kernighan(value);
    if (algorithm == 1) return count_parallel(value);
    if (algorithm == 2) return count_recursive_nybbles(value);
    if (algorithm == 3) return count_fixed_nybbles(value);
    if (algorithm == 4) return count_bw_bytes(value);
    if (algorithm == 5) return count_ar_bytes(value);
    return count_shift_test(value);
}

fn long automotive_bitcount(long iterations) @export("automotive_bitcount") {
    if (iterations < 0 || iterations > MAX_ITERATIONS) return -1;
    long result = 0;
    for (usz algorithm = 0; algorithm < 7; algorithm++) {
        long seed = INITIAL_SEEDS[algorithm];
        long total = 0;
        for (long iteration = 0; iteration < iterations; iteration++) {
            total += count_selected(algorithm, (uint)seed);
            seed += 13;
        }
        result += (long)(algorithm + 1) * total;
    }
    return result;
}
