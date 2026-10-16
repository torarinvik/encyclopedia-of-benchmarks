module vector3_perspective_projection;

const double INPUT_LIMIT = 1000000.0;
const double DENOMINATOR_FLOOR = 0.000001;
const double OUTPUT_LIMIT = 1.0e25;

fn long vector3_perspective_projection(double* input, usz input_len,
                                       double* output, usz output_capacity) @export("vector3_perspective_projection") {
    if (input == null || input_len != 5) return -1;
    for (usz i = 0; i < 5; i++) {
        if (input[i] != input[i] || input[i] < -INPUT_LIMIT || input[i] > INPUT_LIMIT) return -1;
    }
    double denominator = input[2] + input[4];
    if (denominator > -DENOMINATOR_FLOOR && denominator < DENOMINATOR_FLOOR) return -1;
    double x = ((input[0] * input[4]) / denominator) * input[3];
    double y = ((input[1] * input[4]) / denominator) * input[3];
    if (x != x || y != y || x < -OUTPUT_LIMIT || x > OUTPUT_LIMIT ||
        y < -OUTPUT_LIMIT || y > OUTPUT_LIMIT) return -1;
    if (output == null || output_capacity < 2) return -2;
    output[0] = x;
    output[1] = y;
    return 2;
}
