module juggler_sequence;

fn long floor_sqrt(long value) {
    long low = 0, high = value + 1;
    while (high - low > 1) {
        long middle = low + (high - low) / 2;
        if (middle <= value / middle) low = middle;
        else high = middle;
    }
    return low;
}

fn long juggler_sequence(long value, char* output, usz output_capacity) @export("juggler_sequence") {
    if (value < 1 || value > 25) return -1;
    long[16] sequence;
    usz count = 1;
    sequence[0] = value;
    while (sequence[count - 1] != 1) {
        long current = sequence[count - 1];
        sequence[count++] = current % 2 == 0 ? floor_sqrt(current)
            : floor_sqrt(current * current * current);
    }
    usz required = count * 4;
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < count; index++) {
        uint term = sequence[index].u32();
        for (usz byte = 0; byte < 4; byte++)
            output[4 * index + byte] = (char)(term >> (8 * byte));
    }
    return required.long();
}
