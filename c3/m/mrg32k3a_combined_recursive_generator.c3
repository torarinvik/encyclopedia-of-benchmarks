module mrg32k3a_combined_recursive_generator;

const long M1 = 4294967087;
const long M2 = 4294944443;
const long MAX_COUNT = 64;

fn long residue(long value, long modulus) {
    long result = value % modulus;
    if (result < 0) result += modulus;
    return result;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long mrg32k3a_combined_recursive_generator(long* input, usz length,
        char* output, usz capacity) @export("mrg32k3a_combined_recursive_generator") {
    if (input == null || length != 7) return -1;
    for (usz i = 0; i < 3; i++) if (input[i] < 0 || input[i] >= M1) return -1;
    for (usz i = 3; i < 6; i++) if (input[i] < 0 || input[i] >= M2) return -1;
    if ((input[0] | input[1] | input[2]) == 0 ||
        (input[3] | input[4] | input[5]) == 0 ||
        input[6] < 0 || input[6] > MAX_COUNT) return -1;

    usz count = (usz)input[6];
    usz required = count * 8;
    if (capacity < required || (required != 0 && output == null)) return -2;
    if (count == 0) return 0;

    long[3] x1 = {input[0], input[1], input[2]};
    long[3] x2 = {input[3], input[4], input[5]};
    for (usz step = 0; step < count; step++) {
        long next1 = residue(1403580 * x1[1] - 810728 * x1[0], M1);
        long next2 = residue(527612 * x2[2] - 1370589 * x2[0], M2);
        x1[0] = x1[1]; x1[1] = x1[2]; x1[2] = next1;
        x2[0] = x2[1]; x2[1] = x2[2]; x2[2] = next2;
        long z = next1 - next2;
        if (z < 0) z += M1;
        put_i64_le(output, step * 8, z);
    }
    return (long)required;
}
