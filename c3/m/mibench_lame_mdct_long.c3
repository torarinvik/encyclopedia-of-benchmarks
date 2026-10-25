module mibench_lame_mdct_long;

const usz INPUT_COUNT = 18;
const usz MAX_INPUT_LENGTH = 19;
const usz OUTPUT_COUNT = 18;
const double PI = 3.14159265358979323846264338327950288;
const double MAX_FINITE = 1.7976931348623157e308;
extern fn double cos(double value);

fn bool finite_value(double value) {
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE;
}

fn long mibench_lame_mdct_long(double* input, usz input_length,
                               double* output, usz output_capacity)
    @export("mibench_lame_mdct_long")
{
    if (input == null || input_length == 0 || input_length > MAX_INPUT_LENGTH) return -1;
    for (usz k = 0; k < input_length; k++) {
        if (!finite_value(input[k]) || input[k] < -16.0 || input[k] > 16.0) return -1;
    }
    if (input_length != INPUT_COUNT) return -1;

    double[OUTPUT_COUNT] staged = zeroed;
    for (usz m = 0; m < OUTPUT_COUNT; m++) {
        double sum = 0.0;
        for (usz k = 0; k < INPUT_COUNT; k++) {
            usz offset = k < 9 ? 38 : 74;
            double angle = PI * (double)(2 * m + 1) * (double)(4 * k + offset) / 144.0;
            sum += input[k] * cos(angle);
        }
        staged[m] = (4.0 / 36.0) * sum;
    }
    if (output == null || output_capacity < OUTPUT_COUNT) return -2;
    for (usz m = 0; m < OUTPUT_COUNT; m++) output[m] = staged[m];
    return (long)OUTPUT_COUNT;
}
