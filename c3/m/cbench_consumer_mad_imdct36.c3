module cbench_consumer_mad_imdct36;

const usz INPUT_COUNT = 18;
const usz MAX_INPUT_LENGTH = 19;
const usz OUTPUT_COUNT = 36;
const double PI = 3.14159265358979323846264338327950288;
const double MAX_FINITE = 1.7976931348623157e308;
extern fn double cos(double value);

fn bool finite_value(double value) {
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE;
}

fn long cbench_consumer_mad_imdct36(double* input, usz input_length,
                                    double* output, usz output_capacity)
    @export("cbench_consumer_mad_imdct36")
{
    if (input == null || input_length == 0 || input_length > MAX_INPUT_LENGTH) return -1;
    for (usz k = 0; k < input_length; k++) {
        if (!finite_value(input[k]) || input[k] < -16.0 || input[k] > 16.0) return -1;
    }
    if (input_length != INPUT_COUNT) return -1;

    double[OUTPUT_COUNT] staged = zeroed;
    for (usz n = 0; n < OUTPUT_COUNT; n++) {
        double sum = 0.0;
        for (usz k = 0; k < INPUT_COUNT; k++) {
            double angle = PI * (double)(2 * n + 19) * (double)(2 * k + 1) / 72.0;
            sum += input[k] * cos(angle);
        }
        staged[n] = sum;
    }
    if (output == null || output_capacity < OUTPUT_COUNT) return -2;
    for (usz n = 0; n < OUTPUT_COUNT; n++) output[n] = staged[n];
    return (long)OUTPUT_COUNT;
}
