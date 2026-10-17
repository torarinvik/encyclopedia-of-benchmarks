module steinhaus_johnson_trotter;

const usz MAX_LENGTH = 6;

fn void emit_row(int* values, usz length, char* output, usz* offset) {
    for (usz index = 0; index < length; index++) {
        uint bits = (uint)values[index];
        for (usz byte = 0; byte < 4; byte++) {
            output[offset[0]++] = (char)(bits >> (8 * byte));
        }
    }
}

fn long steinhaus_johnson_trotter(int* input, usz length, char* output,
    usz output_capacity) @export("steinhaus_johnson_trotter") {
    if (input == null || length == 0 || length > MAX_LENGTH) return -1;
    usz permutations = 1;
    for (usz factor = 2; factor <= length; factor++) permutations *= factor;
    usz required = 4 * length * permutations;
    if (output == null || output_capacity < required) return -2;

    int[MAX_LENGTH] values;
    usz[MAX_LENGTH] inversion;
    for (usz index = 0; index < MAX_LENGTH; index++) {
        inversion[index] = 0;
        if (index < length) values[index] = input[index];
    }
    usz offset = 0;
    emit_row(&values[0], length, output, &offset);

    usz index = 1;
    while (index < length) {
        if (inversion[index] < index) {
            usz swap_index = index % 2 == 0 ? 0 : inversion[index];
            int temporary = values[swap_index];
            values[swap_index] = values[index];
            values[index] = temporary;
            emit_row(&values[0], length, output, &offset);
            inversion[index] += 1;
            index = 1;
        } else {
            inversion[index] = 0;
            index += 1;
        }
    }
    return (long)required;
}
