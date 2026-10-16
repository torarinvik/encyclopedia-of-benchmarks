module stalin_sort;

const usz MAX_INPUT_LENGTH = 128;

fn long stalin_sort(long* values, usz length, char* output, usz output_capacity)
        @export("stalin_sort") {
    if (length > MAX_INPUT_LENGTH || (length != 0 && values == null)) return -1;
    for (usz i = 0; i < length; i++)
        if (values[i] < -2147483648 || values[i] > 2147483647) return -1;

    usz kept = 0;
    long last = 0;
    for (usz i = 0; i < length; i++) {
        if (kept == 0 || values[i] >= last) {
            kept++;
            last = values[i];
        }
    }
    usz output_bytes = kept * 4;
    if (output == null || output_capacity < output_bytes) return -2;

    usz output_index = 0;
    last = 0;
    for (usz i = 0; i < length; i++) {
        if (output_index == 0 || values[i] >= last) {
            uint bits = (uint)(int)values[i];
            for (usz byte = 0; byte < 4; byte++)
                output[output_index * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
            output_index++;
            last = values[i];
        }
    }
    return (long)output_bytes;
}
