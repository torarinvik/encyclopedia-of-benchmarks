module misc_fp_convert;

const long MAX_ITERATIONS = 256;
const usz VECTOR_LENGTH = 2048;

fn long misc_fp_convert(double* input, usz input_length, double* output, usz output_capacity)
    @export("misc_fp_convert") {
    if (input == null || input_length != 1) return -1;
    double requested = input[0];
    if (requested != requested || requested < 1.0 || requested > (double)MAX_ITERATIONS ||
        requested != (double)(long)requested) return -1;
    if (output == null || output_capacity < 1) return -2;

    long iterations = (long)requested;
    float[VECTOR_LENGTH] x;
    float[VECTOR_LENGTH] y;
    float a = 0.0;
    float b = 1.0;
    double total = 0.0;
    for (long iteration = 0; iteration < iterations; iteration++) {
        if (iteration % 10 != 0) {
            a = 0.0;
            b = 1.0;
        } else {
            a += 0.1;
            b += 0.2;
        }
        for (usz index = 0; index < VECTOR_LENGTH; index++) {
            x[index] = a + (float)index;
            y[index] = b + (float)index;
        }
        double accumulator = 0.0;
        for (usz index = 0; index < VECTOR_LENGTH; index++)
            accumulator += (double)x[index] * (double)y[index];
        total += accumulator;
    }
    output[0] = total;
    return 1;
}
