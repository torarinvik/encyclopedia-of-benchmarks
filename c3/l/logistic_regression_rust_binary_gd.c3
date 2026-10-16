module logistic_regression_rust_binary_gd;

const int MAX_SAMPLES = 32;
const int MAX_FEATURES = 8;
const double Q_SCALE = 1000000.0;

extern fn double exp(double value);

fn void put_f64(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long logistic_regression_rust_binary_gd(long* input, usz length, char* output, usz capacity)
    @export("logistic_regression_rust_binary_gd") {
    if (input == null || length < 4) return -1;
    long mv = input[0], dv = input[1], epochs_v = input[2], alpha_q = input[3];
    if (mv < 1 || mv > MAX_SAMPLES || dv < 1 || dv > MAX_FEATURES
            || epochs_v < 0 || epochs_v > 128 || alpha_q < 1 || alpha_q > 100000) return -1;
    int m = (int)mv, d = (int)dv, epochs = (int)epochs_v;
    if (length != 4 + (usz)m * (usz)d + (usz)m) return -1;
    usz labels_offset = 4 + (usz)m * (usz)d;
    for (usz i = 0; i < (usz)m * (usz)d; i++)
        if (input[4 + i] < -1000000 || input[4 + i] > 1000000) return -1;
    for (int sample = 0; sample < m; sample++)
        if (input[labels_offset + (usz)sample] < 0 || input[labels_offset + (usz)sample] > 1000000) return -1;
    usz required = ((usz)d + 1) * 8;
    if (output == null || capacity < required) return -2;

    double[MAX_FEATURES + 1] theta, gradient, next_theta;
    for (int parameter = 0; parameter <= d; parameter++) theta[parameter] = 0.0;
    double alpha = (double)alpha_q / Q_SCALE;
    for (int epoch = 0; epoch < epochs; epoch++) {
        for (int parameter = 0; parameter <= d; parameter++) gradient[parameter] = 0.0;
        for (int sample = 0; sample < m; sample++) {
            double score = theta[0];
            for (int feature = 0; feature < d; feature++) {
                double x = (double)input[4 + sample * d + feature] / Q_SCALE;
                score += x * theta[feature + 1];
            }
            double prediction = 1.0 / (1.0 + exp(-score));
            double error = prediction - (double)input[labels_offset + (usz)sample] / Q_SCALE;
            gradient[0] += error;
            for (int feature = 0; feature < d; feature++) {
                double x = (double)input[4 + sample * d + feature] / Q_SCALE;
                gradient[feature + 1] += error * x;
            }
        }
        for (int parameter = 0; parameter <= d; parameter++)
            next_theta[parameter] = theta[parameter] - alpha * gradient[parameter];
        for (int parameter = 0; parameter <= d; parameter++) theta[parameter] = next_theta[parameter];
    }
    for (int parameter = 0; parameter <= d; parameter++) put_f64(theta[parameter], output, (usz)parameter * 8);
    return (long)required;
}
