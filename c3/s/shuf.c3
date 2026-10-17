module shuf;

const usz MAX_INPUT_LENGTH = 67;

fn void write_i32_le(char* output, usz index, int value) {
    uint bits = (uint)value;
    usz offset = index * 4;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long shuf(long* input, usz length, char* output, usz capacity) @export("shuf") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long count_raw = input[0], sample_size_raw = input[1];
    if (count_raw < 0 || count_raw > 32 || sample_size_raw < 1 || sample_size_raw > 32) return -1;
    usz count = (usz)count_raw, sample_size = (usz)sample_size_raw;
    if (length != 2 + 2 * count) return -1;

    int[32] items, sample;
    bool[32] occupied = {};
    for (usz index = 0; index < count; index += 1) {
        long value = input[2 + index];
        if (value < -2147483648L || value > 2147483647L) return -1;
        items[index] = (int)value;
    }
    usz initial_count = count < sample_size ? count : sample_size;
    for (usz index = 0; index < initial_count; index += 1) {
        long draw = input[2 + count + index];
        if (draw < 0 || (ulong)draw >= sample_size) return -1;
        usz slot = (usz)draw;
        while (occupied[slot]) {
            slot += 1;
            if (slot == sample_size) slot = 0;
        }
        sample[slot] = items[index];
        occupied[slot] = true;
    }
    if (count >= sample_size) {
        for (usz index = sample_size; index < count; index += 1) {
            long draw = input[2 + count + index];
            if (draw < 0 || (ulong)draw > index) return -1;
            if ((usz)draw < sample_size) sample[(usz)draw] = items[index];
        }
    }

    usz output_count = 0;
    usz output_bytes = initial_count * 4;
    if (output == null || capacity < output_bytes) return -2;
    for (usz slot = 0; slot < sample_size; slot += 1) {
        if (occupied[slot]) write_i32_le(output, output_count++, sample[slot]);
    }
    return (long)output_count;
}
