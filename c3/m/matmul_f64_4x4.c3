module matmul_f64_4x4;

const long MAX_ITERATIONS = 10000;
const usz MATRIX_ELEMENTS = 16;

fn long matmul_f64_4x4(double* input, usz input_length, double* output, usz output_capacity)
    @export("matmul_f64_4x4") {
    if (input == null || input_length != 1) return -1;
    double requested = input[0];
    if (requested != requested || requested < 1.0 || requested > (double)MAX_ITERATIONS ||
        requested != (double)(long)requested) return -1;
    long iterations = (long)requested;

    double[4][4] a = {
        {4.5, 1.3, 6.0, 4.1}, {2.5, 7.2, 7.7, 1.7},
        {6.7, 1.3, 9.4, 1.3}, {1.1, 2.2, 3.0, 2.1}
    };
    double[4][4] b = {
        {1.0, 7.9, 5.1, 3.4}, {6.6, 2.8, 5.4, 9.2},
        {5.0, 4.1, 4.1, 9.9}, {8.4, 3.7, 9.5, 6.4}
    };
    double[16] result;
    for (long iteration = 0; iteration < iterations; iteration++) {
        for (usz row = 0; row < 4; row++) {
            for (usz column = 0; column < 4; column++) {
                double sum = a[row][0] * b[0][column];
                sum += a[row][1] * b[1][column];
                sum += a[row][2] * b[2][column];
                sum += a[row][3] * b[3][column];
                result[row * 4 + column] = sum;
            }
        }
    }
    if (output == null || output_capacity < MATRIX_ELEMENTS) return -2;
    for (usz index = 0; index < MATRIX_ELEMENTS; index++) output[index] = result[index];
    return (long)MATRIX_ELEMENTS;
}
