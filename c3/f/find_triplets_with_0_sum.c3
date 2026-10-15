module find_triplets_with_0_sum;

const MAX_ITEMS = 64;
const BYTES_PER_TRIPLET = 12;

fn void write_i32_le(char* output, usz offset, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn usz enumerate(long* values, usz length, char* output, bool write_output) {
    usz count = 0;
    bool has_last = false;
    long last_a = 0, last_b = 0, last_c = 0;
    for (usz i = 0; i + 2 < length; i++) {
        for (usz j = i + 1; j + 1 < length; j++) {
            for (usz k = j + 1; k < length; k++) {
                if (values[i] + values[j] + values[k] != 0) continue;
                if (has_last && values[i] == last_a && values[j] == last_b && values[k] == last_c) continue;
                if (write_output) {
                    usz offset = count * BYTES_PER_TRIPLET;
                    write_i32_le(output, offset, values[i]);
                    write_i32_le(output, offset + 4, values[j]);
                    write_i32_le(output, offset + 8, values[k]);
                }
                last_a = values[i]; last_b = values[j]; last_c = values[k]; has_last = true;
                count++;
            }
        }
    }
    return count;
}

fn long find_triplets_with_0_sum(long* input, usz length, char* output, usz output_capacity)
    @export("find_triplets_with_0_sum") {
    if (length > MAX_ITEMS || (length > 0 && input == null)) return -1;
    long[MAX_ITEMS] values;
    for (usz i = 0; i < length; i++) {
        if (input[i] < -100000 || input[i] > 100000) return -1;
        values[i] = input[i];
    }
    for (usz i = 1; i < length; i++) {
        long key = values[i];
        usz j = i;
        while (j > 0 && values[j - 1] > key) { values[j] = values[j - 1]; j--; }
        values[j] = key;
    }
    usz count = enumerate(&values[0], length, null, false);
    if (count == 0) return 0;
    usz needed = count * BYTES_PER_TRIPLET;
    if (output == null || output_capacity < needed) return -2;
    return (long)enumerate(&values[0], length, output, true);
}
