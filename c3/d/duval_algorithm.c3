module duval_algorithm;

const MAX_LENGTH = 4096;

fn bool valid_input(long* values, usz length) {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return false;
    for (usz i = 0; i < length; i++) {
        if (values[i] < 0 || values[i] > 127) return false;
    }
    return true;
}

fn usz factor_count(long* values, usz length) {
    usz start = 0, count = 0;
    while (start < length) {
        usz end = start + 1, repeat = start;
        while (end < length && values[repeat] <= values[end]) {
            if (values[repeat] < values[end]) repeat = start;
            else repeat += 1;
            end += 1;
        }
        usz factor_length = end - repeat;
        while (start <= repeat) {
            count += 1;
            start += factor_length;
        }
    }
    return count;
}

fn void store_u32_le(ubyte* output, usz offset, usz value) {
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (ubyte)((value >> (8 * byte)) & 255);
    }
}

fn void write_factors(long* values, usz length, ubyte* output) {
    usz start = 0, factor_index = 0;
    while (start < length) {
        usz end = start + 1, repeat = start;
        while (end < length && values[repeat] <= values[end]) {
            if (values[repeat] < values[end]) repeat = start;
            else repeat += 1;
            end += 1;
        }
        usz factor_length = end - repeat;
        while (start <= repeat) {
            store_u32_le(output, 4 * factor_index, factor_length);
            factor_index += 1;
            start += factor_length;
        }
    }
}

fn long duval_algorithm(long* values, usz length, ubyte* output, usz output_capacity)
        @export("duval_algorithm") {
    if (!valid_input(values, length)) return -1;
    usz count = factor_count(values, length);
    usz required = 4 * count;
    if (required == 0) return 0;
    if (output == null || output_capacity < required) return -2;
    write_factors(values, length, output);
    return (long)count;
}
