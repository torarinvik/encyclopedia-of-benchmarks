module merge_intervals;

const usz MAX_INTERVALS = 256;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_INTERVALS;

fn void store_i32_le(char* output, usz offset, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte += 1)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long merge_intervals(long* values, usz length, char* output, usz output_capacity)
    @export("merge_intervals") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_count = values[0];
    if (raw_count < 0 || raw_count > (long)MAX_INTERVALS ||
        length != 1 + 2 * (usz)raw_count) return -1;

    usz count = (usz)raw_count;
    long[MAX_INTERVALS] starts;
    long[MAX_INTERVALS] ends;
    for (usz i = 0; i < count; i += 1) {
        long start = values[1 + 2 * i];
        long end = values[2 + 2 * i];
        if (start < -2147483648 || start > 2147483647 ||
            end < -2147483648 || end > 2147483647 || start > end) return -1;
        starts[i] = start;
        ends[i] = end;
    }

    for (usz i = 1; i < count; i += 1) {
        long start = starts[i];
        long end = ends[i];
        usz position = i;
        while (position > 0 && starts[position - 1] > start) {
            starts[position] = starts[position - 1];
            ends[position] = ends[position - 1];
            position -= 1;
        }
        starts[position] = start;
        ends[position] = end;
    }

    usz merged = 0;
    for (usz i = 0; i < count; i += 1) {
        if (merged != 0 && starts[i] <= ends[merged - 1]) {
            if (ends[i] > ends[merged - 1]) ends[merged - 1] = ends[i];
        } else {
            starts[merged] = starts[i];
            ends[merged] = ends[i];
            merged += 1;
        }
    }

    usz byte_count = 8 * merged;
    if (output == null || output_capacity < byte_count) return -2;
    for (usz i = 0; i < merged; i += 1) {
        store_i32_le(output, 8 * i, starts[i]);
        store_i32_le(output, 8 * i + 4, ends[i]);
    }
    return (long)byte_count;
}
