module mutate;

const usz MAX_GENES = 64;

fn long mutate(double* input, usz length, double* output, usz capacity) @export("mutate") {
    if (input == null || length < 2 || length > 130) return -1;
    double mu = input[0], count_value = input[1];
    if (mu != mu || mu < 0.0 || mu > 1.0) return -1;
    if (count_value != count_value || count_value < 0.0 || count_value > MAX_GENES || count_value != (double)(long)count_value) return -1;
    usz count = (usz)(long)count_value;
    if (length != 2 + 2 * count) return -1;
    for (usz index = 0; index < count; index++) {
        double gene = input[2 + index];
        if (gene != 0.0 && gene != 1.0) return -1;
    }
    for (usz index = 0; index < count; index++) {
        double draw = input[2 + count + index];
        if (draw != draw || draw < 0.0 || draw >= 1.0) return -1;
    }
    if (output == null || capacity < count) return -2;
    for (usz index = 0; index < count; index++) {
        double gene = input[2 + index];
        double draw = input[2 + count + index];
        output[index] = draw < mu ? 1.0 - gene : gene;
    }
    return (long)count;
}
