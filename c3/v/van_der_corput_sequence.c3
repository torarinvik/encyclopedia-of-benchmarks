module van_der_corput_sequence;

const long MAX_INDEX = 4096;
const long MAX_COUNT = 128;

fn void store_u64_le(char* output, usz offset, ulong value) {
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((value >> (byte * 8)) & 255);
}

fn void radical_inverse(long index, long base, ulong* numerator, ulong* denominator) {
    ulong reversed = 0;
    ulong scale = 1;
    while (index > 0) {
        reversed = reversed * (ulong)base + (ulong)(index % base);
        scale *= (ulong)base;
        index /= base;
    }
    *numerator = reversed;
    *denominator = scale;
}

fn long van_der_corput_sequence(long* input, usz length, char* output,
        usz output_capacity) @export("van_der_corput_sequence") {
    if (input == null || length != 3) return -1;
    long base = input[0];
    long first_index = input[1];
    long count = input[2];
    if (base < 2 || base > 16 || first_index < 1 || first_index > MAX_INDEX
        || count < 0 || count > MAX_COUNT
        || (count > 0 && first_index + count - 1 > MAX_INDEX)) return -1;

    usz output_bytes = (usz)count * 16;
    if (output == null || output_capacity < output_bytes) return -2;
    for (long offset = 0; offset < count; offset++) {
        ulong numerator = 0;
        ulong denominator = 1;
        radical_inverse(first_index + offset, base, &numerator, &denominator);
        usz position = (usz)offset * 16;
        store_u64_le(output, position, numerator);
        store_u64_le(output, position + 8, denominator);
    }
    return (long)output_bytes;
}
