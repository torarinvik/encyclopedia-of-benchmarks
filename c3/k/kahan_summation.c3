module kahan_summation;

const usz MAX_LENGTH = 256;
const double MAX_ABS_VALUE = 1.0e100;

fn long kahan_summation(double* values, usz length, double* output, usz capacity) @export("kahan_summation") {
    if (values == null || length > MAX_LENGTH) return -1;
    for (usz i = 0; i < length; i++) {
        double value = values[i];
        if (value != value || value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return -1;
    }
    if (output == null || capacity < 1) return -2;

    double sum = 0.0;
    double correction = 0.0;
    for (usz i = 0; i < length; i++) {
        double adjusted = values[i] - correction;
        double next = sum + adjusted;
        correction = (next - sum) - adjusted;
        sum = next;
    }
    output[0] = sum;
    return 1;
}
