module hamming_numbers;

const usz MAX_COUNT = 32;

fn long hamming_numbers(long* input, usz length, char* output, usz output_capacity)
        @export("hamming_numbers") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > (long)MAX_COUNT) return -1;
    usz count = (usz)input[0];
    usz output_bytes = count * 8;
    if (output_capacity < output_bytes || output == null) return -2;

    usz[MAX_COUNT] values;
    for (usz index = 0; index < MAX_COUNT; index++) values[index] = 0;
    values[0] = 1;
    usz i2 = 0, i3 = 0, i5 = 0;
    for (usz index = 1; index < count; index++) {
        usz c2 = values[i2] * 2;
        usz c3 = values[i3] * 3;
        usz c5 = values[i5] * 5;
        usz next = c2 < c3 ? c2 : c3;
        if (c5 < next) next = c5;
        values[index] = next;
        if (c2 == next) i2++;
        if (c3 == next) i3++;
        if (c5 == next) i5++;
    }
    for (usz index = 0; index < count; index++) {
        for (usz byte = 0; byte < 8; byte++) output[index * 8 + byte] = (char)(values[index] >> (byte * 8));
    }
    return (long)count;
}
