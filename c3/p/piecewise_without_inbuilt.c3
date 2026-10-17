module piecewise_without_inbuilt;

fn long piecewise_without_inbuilt(double* input, usz input_length,
                                  double* output, usz output_capacity) @export("piecewise_without_inbuilt") {
    if (input == null || input_length != 1) return -1;
    double x = input[0];
    if (x != x || x < -10.0 || x > 10.0) return -1;

    double y = x <= -0.5 ? 0.0 : (x < 0.5 ? x : 1.0);
    if (output == null || output_capacity < 1) return -2;
    output[0] = y;
    return 1;
}
