#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INPUT_LENGTH 15u
#define MAX_EPOCHS 12u
#define OUTPUT_WIDTH 3u
#define MAX_OUTPUT_LENGTH 26u

static const double initial_w1[3][2] = {
    {0.30471707975443135, -1.0399841062404955},
    {0.7504511958064572, 0.9405647163912139},
    {-1.9510351886538364, -1.302179506862318},
};
static const double initial_w2[2][3] = {
    {0.12784040316728537, -0.3162425923435822, -0.016801157504288795},
    {-0.85304392757358, 0.8793979748628286, 0.7777919354289483},
};

static void forward(const double row[3], const double w1[3][2], const double w2[2][3],
                    double z1[2], double hidden[2], double output[3]) {
    for (size_t j = 0; j < 2; ++j) {
        z1[j] = 0.0;
        for (size_t i = 0; i < 3; ++i) z1[j] += row[i] * w1[i][j];
        hidden[j] = z1[j] > 0.0 ? z1[j] : 0.0;
    }
    for (size_t k = 0; k < OUTPUT_WIDTH; ++k) {
        output[k] = 0.0;
        for (size_t j = 0; j < 2; ++j) output[k] += hidden[j] * w2[j][k];
    }
}

int64_t multilayer_perceptron_classifier(const double *input, size_t input_length,
                                         double *output, size_t output_capacity) {
    if (input == NULL || input_length != INPUT_LENGTH) return -1;
    for (size_t index = 0; index < input_length; ++index) {
        if (!isfinite(input[index])) return -1;
    }

    const double epochs_value = input[0];
    const double learning_rate = input[1];
    const double gamma = input[2];
    if (epochs_value < 1.0 || epochs_value > (double)MAX_EPOCHS ||
        epochs_value != trunc(epochs_value)) return -1;
    if (learning_rate != 0.05 && learning_rate != 0.1 && learning_rate != 0.2) return -1;
    if (gamma != 0.5 && gamma != 0.75 && gamma != 1.0) return -1;
    const size_t epochs = (size_t)epochs_value;

    for (size_t index = 0; index < 8; ++index) {
        const double feature = input[3 + index];
        const double scaled = feature * 4.0;
        if (feature < -2.0 || feature > 2.0 || scaled != trunc(scaled)) return -1;
    }
    int labels[4];
    for (size_t row = 0; row < 4; ++row) {
        const double label = input[11 + row];
        if (label < 0.0 || label > 2.0 || label != trunc(label)) return -1;
        labels[row] = (int)label;
    }

    double w1[3][2];
    double w2[2][3];
    for (size_t i = 0; i < 3; ++i) {
        for (size_t j = 0; j < 2; ++j) w1[i][j] = initial_w1[i][j];
    }
    for (size_t j = 0; j < 2; ++j) {
        for (size_t k = 0; k < OUTPUT_WIDTH; ++k) w2[j][k] = initial_w2[j][k];
    }

    double rates = learning_rate;
    double accuracy_history[MAX_EPOCHS];
    double loss_history[MAX_EPOCHS];
    for (size_t epoch = 0; epoch < epochs; ++epoch) {
        for (size_t row_index = 0; row_index < 3; ++row_index) {
            const double row[3] = {input[3 + row_index * 2], input[4 + row_index * 2], 1.0};
            double z1[2], hidden[2], prediction[3];
            forward(row, w1, w2, z1, hidden, prediction);

            double target[3];
            for (size_t k = 0; k < OUTPUT_WIDTH; ++k) target[k] = labels[row_index] == (int)k ? 0.99 : 0.0;
            double delta_out[3];
            for (size_t k = 0; k < OUTPUT_WIDTH; ++k) delta_out[k] = prediction[k] - target[k];
            double delta_hidden[2];
            for (size_t j = 0; j < 2; ++j) {
                delta_hidden[j] = 0.0;
                for (size_t k = 0; k < OUTPUT_WIDTH; ++k) delta_hidden[j] += delta_out[k] * w2[j][k];
                if (z1[j] <= 0.0) delta_hidden[j] = 0.0;
            }

            for (size_t i = 0; i < 3; ++i) {
                for (size_t j = 0; j < 2; ++j) {
                    const double gradient = row[i] * delta_hidden[j];
                    w1[i][j] -= rates * gradient;
                }
            }
            for (size_t j = 0; j < 2; ++j) {
                for (size_t k = 0; k < OUTPUT_WIDTH; ++k) {
                    const double gradient = hidden[j] * delta_out[k];
                    w2[j][k] -= rates * gradient;
                }
            }
        }

        const double test_row[3] = {input[9], input[10], 1.0};
        double z1[2], hidden[2], prediction[3];
        forward(test_row, w1, w2, z1, hidden, prediction);
        const int test_label = labels[3];
        size_t predicted_class = 0;
        for (size_t k = 1; k < OUTPUT_WIDTH; ++k) {
            if (prediction[k] > prediction[predicted_class]) predicted_class = k;
        }
        accuracy_history[epoch] = predicted_class == (size_t)test_label ? 1.0 : 0.0;
        double loss_sum = 0.0;
        for (size_t k = 0; k < OUTPUT_WIDTH; ++k) {
            const double target = test_label == (int)k ? 0.99 : 0.0;
            const double difference = prediction[k] - target;
            loss_sum += difference * difference;
        }
        loss_history[epoch] = loss_sum / 2.0;
        rates *= gamma;
    }

    double staged[MAX_OUTPUT_LENGTH];
    size_t result_length = 0;
    staged[result_length++] = (double)epochs;
    double accuracy_sum = 0.0;
    for (size_t epoch = 0; epoch < epochs; ++epoch) {
        staged[result_length++] = accuracy_history[epoch];
        accuracy_sum += accuracy_history[epoch];
    }
    for (size_t epoch = 0; epoch < epochs; ++epoch) staged[result_length++] = loss_history[epoch];
    staged[result_length++] = accuracy_sum / (double)epochs;

    if (output == NULL || output_capacity < result_length) return -2;
    for (size_t index = 0; index < result_length; ++index) output[index] = staged[index];
    return (int64_t)result_length;
}
