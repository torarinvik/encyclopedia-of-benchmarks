module kalman_filter;

extern fn double floor(double value);

const usz MAX_STEPS = 12;
const usz MAX_PARSEABLE_LENGTH = 64;
const double SCALE = 1000000.0;

fn long kalman_filter(double* input, usz length, double* output, usz output_capacity)
    @export("kalman_filter") {
    if (input == null || length < 5 || length > MAX_PARSEABLE_LENGTH) return -1;
    for (usz index = 0; index < length; index++) {
        if (input[index] != input[index] || floor(input[index]) != input[index]) return -1;
    }
    double raw_steps = input[4];
    if (raw_steps < 1.0 || raw_steps > (double)MAX_STEPS) return -1;
    usz steps = (usz)raw_steps;
    if (length != 5 + steps) return -1;
    if (input[0] < -1000000000.0 || input[0] > 1000000000.0 ||
        input[1] < 0.0 || input[1] > 1000000000000.0 ||
        input[2] < 0.0 || input[2] > 1000000000000.0 ||
        input[3] < 1.0 || input[3] > 1000000000000.0) return -1;
    for (usz index = 0; index < steps; index++) {
        double measurement = input[5 + index];
        if (measurement < -1000000000.0 || measurement > 1000000000.0) return -1;
    }

    usz required = 3 * steps;
    if (output == null || output_capacity < required) return -2;
    double estimate = input[0] / SCALE;
    double covariance = input[1] / SCALE;
    double process_noise = input[2] / SCALE;
    double measurement_noise = input[3] / SCALE;
    for (usz step = 0; step < steps; step++) {
        double measurement = input[5 + step] / SCALE;
        estimate += 0.0;
        covariance += process_noise;
        double innovation_variance = covariance + measurement_noise;
        double gain = covariance / innovation_variance;
        estimate += gain * (measurement - estimate);
        covariance = covariance * measurement_noise / innovation_variance;
        output[3 * step] = estimate;
        output[3 * step + 1] = covariance;
        output[3 * step + 2] = gain;
    }
    return (long)required;
}
