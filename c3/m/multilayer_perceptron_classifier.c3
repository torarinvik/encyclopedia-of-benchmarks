module multilayer_perceptron_classifier;

const usz INPUT_LENGTH = 15;
const usz MAX_INPUT_LENGTH = 16;
const usz MAX_OUTPUT_LENGTH = 26;

fn bool finite_value(double x) {
    return x == x && x < 1e300 && x > -1e300;
}

fn long multilayer_perceptron_classifier(double* input, usz input_length,
                                           double* output, usz output_capacity)
    @export("multilayer_perceptron_classifier") {
    if (input == null || input_length > MAX_INPUT_LENGTH || input_length != INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) if (!finite_value(input[i])) return -1L;

    if (input[0] < 1.0 || input[0] > 12.0 || (double)(long)input[0] != input[0]) return -1L;
    long epochs = (long)input[0];
    double initial_rate = input[1];
    double gamma = input[2];
    if (!(initial_rate == 0.05 || initial_rate == 0.1 || initial_rate == 0.2)) return -1L;
    if (!(gamma == 0.5 || gamma == 0.75 || gamma == 1.0)) return -1L;

    double[8] features = zeroed;
    for (usz i = 0; i < 8; i++) {
        double value = input[3 + i];
        if (value < -2.0 || value > 2.0) return -1L;
        double scaled = value * 4.0;
        if ((double)(long)scaled != scaled) return -1L;
        features[i] = value;
    }
    long[4] labels = zeroed;
    for (usz i = 0; i < 4; i++) {
        double value = input[11 + i];
        if (value < 0.0 || value > 2.0 || (double)(long)value != value) return -1L;
        labels[i] = (long)value;
    }

    // The first model after a fresh Python import, default_rng(42), with He scaling.
    double[6] w1 = zeroed;
    w1[0] = 0.30471707975443135; w1[1] = -1.0399841062404955;
    w1[2] = 0.7504511958064572;  w1[3] = 0.9405647163912139;
    w1[4] = -1.9510351886538364; w1[5] = -1.302179506862318;
    double[6] w2 = zeroed;
    w2[0] = 0.12784040316728537; w2[1] = -0.3162425923435822; w2[2] = -0.016801157504288795;
    w2[3] = -0.85304392757358;   w2[4] = 0.8793979748628286;  w2[5] = 0.7777919354289483;

    double[MAX_OUTPUT_LENGTH] staged = zeroed;
    staged[0] = (double)epochs;
    double rate = initial_rate;
    for (usz epoch = 0; epoch < (usz)epochs; epoch++) {
        for (usz row_index = 0; row_index < 3; row_index++) {
            double[3] row = { features[row_index * 2], features[row_index * 2 + 1], 1.0 };
            double[2] z1 = zeroed;
            double[2] hidden = zeroed;
            for (usz j = 0; j < 2; j++) {
                double sum = 0.0;
                for (usz i = 0; i < 3; i++) sum += row[i] * w1[i * 2 + j];
                z1[j] = sum;
                hidden[j] = sum > 0.0 ? sum : 0.0;
            }
            double[3] z2 = zeroed;
            double[3] delta_out = zeroed;
            for (usz k = 0; k < 3; k++) {
                double sum = 0.0;
                for (usz j = 0; j < 2; j++) sum += hidden[j] * w2[j * 3 + k];
                z2[k] = sum;
                double target = labels[row_index] == (long)k ? 0.99 : 0.0;
                delta_out[k] = sum - target;
            }
            double[2] delta_hidden = zeroed;
            for (usz j = 0; j < 2; j++) {
                double sum = 0.0;
                for (usz k = 0; k < 3; k++) sum += delta_out[k] * w2[j * 3 + k];
                delta_hidden[j] = sum * (z1[j] > 0.0 ? 1.0 : 0.0);
            }
            double[6] grad_w1 = zeroed;
            for (usz i = 0; i < 3; i++)
                for (usz j = 0; j < 2; j++) grad_w1[i * 2 + j] = row[i] * delta_hidden[j];
            double[6] grad_w2 = zeroed;
            for (usz j = 0; j < 2; j++)
                for (usz k = 0; k < 3; k++) grad_w2[j * 3 + k] = hidden[j] * delta_out[k];
            for (usz i = 0; i < 6; i++) w1[i] -= rate * grad_w1[i];
            for (usz i = 0; i < 6; i++) w2[i] -= rate * grad_w2[i];
        }

        double[3] test_row = { features[6], features[7], 1.0 };
        double[2] hidden_test = zeroed;
        for (usz j = 0; j < 2; j++) {
            double sum = 0.0;
            for (usz i = 0; i < 3; i++) sum += test_row[i] * w1[i * 2 + j];
            hidden_test[j] = sum > 0.0 ? sum : 0.0;
        }
        double[3] test_output = zeroed;
        for (usz k = 0; k < 3; k++)
            for (usz j = 0; j < 2; j++) test_output[k] += hidden_test[j] * w2[j * 3 + k];
        usz predicted = 0;
        for (usz k = 1; k < 3; k++) if (test_output[k] > test_output[predicted]) predicted = k;
        staged[1 + epoch] = (long)predicted == labels[3] ? 1.0 : 0.0;
        double loss_sum = 0.0;
        for (usz k = 0; k < 3; k++) {
            double target = labels[3] == (long)k ? 0.99 : 0.0;
            double difference = test_output[k] - target;
            loss_sum += difference * difference;
        }
        staged[1 + (usz)epochs + epoch] = loss_sum / 2.0;
        rate *= gamma;
    }
    double accuracy_sum = 0.0;
    for (usz epoch = 0; epoch < (usz)epochs; epoch++) accuracy_sum += staged[1 + epoch];
    staged[1 + 2 * (usz)epochs] = accuracy_sum / (double)epochs;
    usz result_length = 2 * (usz)epochs + 2;
    if (output == null || output_capacity < result_length) return -2L;
    for (usz i = 0; i < result_length; i++) output[i] = staged[i];
    return (long)result_length;
}
