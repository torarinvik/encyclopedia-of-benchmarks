module misc_dt;

extern fn float cosf(float value);
extern fn float sinf(float value);

const long MAX_ITERATIONS = 128;
const usz MAX_VECTOR_SIZE = 64;

fn long misc_dt(double* input, usz input_length, double* output, usz output_capacity)
    @export("misc_dt") {
    if (input == null || input_length != 2) return -1;
    double requested_iterations = input[0];
    double requested_size = input[1];
    if (requested_iterations != requested_iterations || requested_iterations < 1.0 ||
        requested_iterations > (double)MAX_ITERATIONS ||
        requested_iterations != (double)(long)requested_iterations ||
        requested_size != requested_size || requested_size < 1.0 ||
        requested_size > (double)MAX_VECTOR_SIZE ||
        requested_size != (double)(usz)requested_size) return -1;
    long iterations = (long)requested_iterations;
    usz size = (usz)requested_size;
    if (output == null || output_capacity < size) return -2;

    double[MAX_VECTOR_SIZE] numerator;
    double[MAX_VECTOR_SIZE] denominator;
    for (usz index = 0; index < size; index++) {
        numerator[index] = 1.0000001 * (double)cosf((float)(size - index));
        denominator[index] = 1.0 + 1e-10 * (double)sinf((float)index);
    }
    for (long iteration = 0; iteration < iterations; iteration++) {
        for (usz index = 0; index < size; index++) numerator[index] /= denominator[index];
    }
    for (usz index = 0; index < size; index++) output[index] = numerator[index];
    return (long)size;
}
