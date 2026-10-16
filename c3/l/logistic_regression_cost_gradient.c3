module lr_cost_gradient;

const int MAX_SAMPLES = 64;
const int MAX_FEATURES = 8;
const double Q_SCALE = 1000000.0;

extern fn double exp(double value);
extern fn double log(double value);
extern fn void* memcpy(void* destination, void* source, usz length);

fn void put_f64(double value, char* output, usz offset) {
    ulong bits = 0;
    memcpy(&bits, &value, 8);
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long logistic_regression_cost_gradient(long* input, usz length, char* output, usz capacity)
    @export("logistic_regression_cost_gradient") {
    if (input == null || length < 2) return -1;
    long mv = input[0];
    long dv = input[1];
    if (mv < 1 || mv > MAX_SAMPLES || dv < 1 || dv > MAX_FEATURES) return -1;
    usz m = (usz)mv;
    usz d = (usz)dv;
    usz features_offset = 2;
    usz theta_offset = features_offset + m * d;
    usz labels_offset = theta_offset + d;
    if (length != labels_offset + m) return -1;
    for (usz index = 0; index < m * d; index++) {
        if (input[features_offset + index] < -1000000 || input[features_offset + index] > 1000000) return -1;
    }
    for (usz feature = 0; feature < d; feature++) {
        if (input[theta_offset + feature] < -1000000 || input[theta_offset + feature] > 1000000) return -1;
    }
    for (usz sample = 0; sample < m; sample++) {
        if (input[labels_offset + sample] != 0 && input[labels_offset + sample] != 1) return -1;
    }
    usz required = (d + 1) * 8;
    if (output == null || capacity < required) return -2;

    double loss = 0.0;
    double[MAX_FEATURES] gradient;
    for (usz feature = 0; feature < MAX_FEATURES; feature++) gradient[feature] = 0.0;
    for (usz sample = 0; sample < m; sample++) {
        double score = 0.0;
        for (usz feature = 0; feature < d; feature++) {
            double x = (double)input[features_offset + sample * d + feature] / Q_SCALE;
            double theta = (double)input[theta_offset + feature] / Q_SCALE;
            score += x * theta;
        }
        double probability = 1.0 / (1.0 + exp(-score));
        double label = (double)input[labels_offset + sample];
        loss += -label * log(probability) - (1.0 - label) * log(1.0 - probability);
        double error = probability - label;
        for (usz feature = 0; feature < d; feature++) {
            double x = (double)input[features_offset + sample * d + feature] / Q_SCALE;
            gradient[feature] += error * x;
        }
    }
    put_f64(loss / (double)m, output, 0);
    for (usz feature = 0; feature < d; feature++) {
        put_f64(gradient[feature] / (double)m, output, (feature + 1) * 8);
    }
    return (long)required;
}
