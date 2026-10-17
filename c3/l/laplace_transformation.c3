module laplace_transformation;

extern fn double exp(double value);

const long MAX_SAMPLE_COUNT = 64;
const usz MAX_INPUT_LENGTH = 68;
const long MIN_SAMPLE_MICRO = -1000000;
const long MAX_SAMPLE_MICRO = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double laplace_transformation(long* input, usz length) @export("laplace_transformation") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long sample_count_value = input[0], s_milli = input[1], dt_micro = input[2];
    if (sample_count_value < 1 || sample_count_value > MAX_SAMPLE_COUNT) return INVALID_RESULT;
    usz sample_count = (usz)sample_count_value;
    if (length != sample_count + 3 || s_milli < 0 || s_milli > 1000 ||
        dt_micro < 1 || dt_micro > 1000000) return INVALID_RESULT;

    double[64] samples;
    for (usz index = 0; index < sample_count; index++) {
        long sample = input[3 + index];
        if (sample < MIN_SAMPLE_MICRO || sample > MAX_SAMPLE_MICRO) return INVALID_RESULT;
        samples[index] = (double)sample / 1000000.0;
    }
    if (sample_count == 1) return 0.0;

    double s_value = (double)s_milli / 1000.0;
    double delta_t = (double)dt_micro / 1000000.0;
    double stop = (double)(sample_count - 1) * delta_t;
    double step = stop / (double)(sample_count - 1);
    double[64] integrand;
    for (usz index = 0; index < sample_count; index++) {
        double time = index == sample_count - 1 ? stop : (double)index * step;
        integrand[index] = samples[index] * exp(-s_value * time);
    }

    double result = 0.0;
    for (usz index = 0; index + 1 < sample_count; index++)
        result += (delta_t * (integrand[index] + integrand[index + 1])) / 2.0;
    return result;
}
