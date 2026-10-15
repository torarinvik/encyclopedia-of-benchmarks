module counting_sort_string;

const long MAX_TEXT_LENGTH = 4095;

fn long counting_sort_string(long* values, usz length, char* output, usz output_capacity)
    @export("counting_sort_string") {
    if (values == null || length < 1 || length > 4096) return -1;
    long count = values[0];
    if (count < 0 || count > MAX_TEXT_LENGTH || length != (usz)(count + 1)) return -1;

    usz[256] frequencies;
    for (usz value = 0; value < 256; value++) frequencies[value] = 0;
    for (usz index = 0; index < (usz)count; index++) {
        long value = values[index + 1];
        if (value < 33 || value > 126) return -1;
        frequencies[(usz)value] += 1;
    }
    if (output == null || output_capacity < (usz)count) return -2;

    for (usz value = 1; value < 256; value++) frequencies[value] += frequencies[value - 1];
    for (usz index = (usz)count; index > 0; index--) {
        usz value = (usz)values[index];
        frequencies[value] -= 1;
        output[frequencies[value]] = (char)value;
    }
    return count;
}
