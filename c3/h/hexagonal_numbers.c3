module hexagonal_numbers;

const long MAX_LENGTH = 1024;
const usz BYTES_PER_VALUE = 8;

fn void store_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < BYTES_PER_VALUE; byte++)
        output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

// Emit h_i = i * (2i - 1) for i from zero through length - one.
fn long hexagonal_numbers(long length, char* output, usz output_capacity)
    @export("hexagonal_numbers") {
    if (length < 1 || length > MAX_LENGTH) return -1;
    usz n = (usz)length;
    usz required = n * BYTES_PER_VALUE;
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < n; index++) {
        long i = (long)index;
        store_i64_le(output, index * BYTES_PER_VALUE, i * (2 * i - 1));
    }
    return length;
}
