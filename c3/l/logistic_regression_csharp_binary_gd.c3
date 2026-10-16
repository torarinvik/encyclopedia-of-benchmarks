module logistic_regression_csharp_binary_gd;

const int MAX_SAMPLES = 32;
const int MAX_FEATURES = 8;
const double Q_SCALE = 1000000.0;
const double INVALID_RESULT = -1.0e300;

extern fn double exp(double value);

fn double logistic_regression_csharp_binary_gd(long* input, usz length)
    @export("logistic_regression_csharp_binary_gd") {
    if (input == null || length < 4) return INVALID_RESULT;
    long mv = input[0], dv = input[1], epochs_v = input[2], rate_q = input[3];
    if (mv < 1 || mv > MAX_SAMPLES || dv < 1 || dv > MAX_FEATURES ||
        epochs_v < 0 || epochs_v > 128 || rate_q < 1 || rate_q > 100000) return INVALID_RESULT;
    int m = (int)mv, d = (int)dv, epochs = (int)epochs_v;
    usz feature_count = (usz)m * (usz)d;
    usz labels_offset = 4 + feature_count;
    usz query_offset = labels_offset + (usz)m;
    if (length != query_offset + (usz)d) return INVALID_RESULT;
    for (usz i = 0; i < feature_count; i++)
        if (input[4 + i] < -1000000 || input[4 + i] > 1000000) return INVALID_RESULT;
    for (int sample = 0; sample < m; sample++)
        if (input[labels_offset + (usz)sample] != 0 && input[labels_offset + (usz)sample] != 1) return INVALID_RESULT;
    for (int feature = 0; feature < d; feature++)
        if (input[query_offset + (usz)feature] < -1000000 || input[query_offset + (usz)feature] > 1000000) return INVALID_RESULT;

    double[MAX_FEATURES] weights, gradient;
    for (int feature = 0; feature < MAX_FEATURES; feature++) {
        weights[feature] = 0.0;
        gradient[feature] = 0.0;
    }
    double bias = 0.0;
    double learning_rate = (double)rate_q / Q_SCALE;
    for (int epoch = 0; epoch < epochs; epoch++) {
        for (int feature = 0; feature < d; feature++) gradient[feature] = 0.0;
        double bias_gradient = 0.0;
        for (int sample = 0; sample < m; sample++) {
            double dot = 0.0;
            for (int feature = 0; feature < d; feature++) {
                double x = (double)input[4 + (usz)sample * (usz)d + (usz)feature] / Q_SCALE;
                dot += x * weights[feature];
            }
            double linear = dot + bias;
            double prediction = 1.0 / (1.0 + exp(-linear));
            double error = prediction - (double)input[labels_offset + (usz)sample];
            for (int feature = 0; feature < d; feature++) {
                double x = (double)input[4 + (usz)sample * (usz)d + (usz)feature] / Q_SCALE;
                gradient[feature] += error * x;
            }
            bias_gradient += error;
        }
        for (int feature = 0; feature < d; feature++)
            weights[feature] -= learning_rate * gradient[feature] / (double)m;
        bias -= learning_rate * bias_gradient / (double)m;
    }
    double query_dot = 0.0;
    for (int feature = 0; feature < d; feature++) {
        double x = (double)input[query_offset + (usz)feature] / Q_SCALE;
        query_dot += x * weights[feature];
    }
    double query_linear = query_dot + bias;
    return 1.0 / (1.0 + exp(-query_linear));
}
