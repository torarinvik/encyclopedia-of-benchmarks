#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t input_length = 15;
constexpr std::size_t max_epochs = 12;
constexpr std::size_t output_width = 3;
constexpr std::size_t max_output_length = 26;

constexpr double initial_w1[3][2] = {
    {0.30471707975443135, -1.0399841062404955},
    {0.7504511958064572, 0.9405647163912139},
    {-1.9510351886538364, -1.302179506862318},
};
constexpr double initial_w2[2][3] = {
    {0.12784040316728537, -0.3162425923435822, -0.016801157504288795},
    {-0.85304392757358, 0.8793979748628286, 0.7777919354289483},
};

void forward(const double row[3], const double w1[3][2], const double w2[2][3],
    double z1[2], double hidden[2], double output[3]) noexcept {
    for (std::size_t j = 0; j < 2; ++j) {
        z1[j] = 0.0;
        for (std::size_t i = 0; i < 3; ++i) z1[j] += row[i] * w1[i][j];
        hidden[j] = z1[j] > 0.0 ? z1[j] : 0.0;
    }
    for (std::size_t k = 0; k < output_width; ++k) {
        output[k] = 0.0;
        for (std::size_t j = 0; j < 2; ++j) output[k] += hidden[j] * w2[j][k];
    }
}
}

extern "C" std::int64_t multilayer_perceptron_classifier(const double* input,
    std::size_t length, double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length != input_length) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (!std::isfinite(input[index])) return -1;
    }

    const double epochs_value = input[0];
    const double learning_rate = input[1];
    const double gamma = input[2];
    if (epochs_value < 1.0 || epochs_value > static_cast<double>(max_epochs) ||
        epochs_value != std::trunc(epochs_value)) return -1;
    if (learning_rate != 0.05 && learning_rate != 0.1 && learning_rate != 0.2) return -1;
    if (gamma != 0.5 && gamma != 0.75 && gamma != 1.0) return -1;
    const auto epochs = static_cast<std::size_t>(epochs_value);

    for (std::size_t index = 0; index < 8; ++index) {
        const double feature = input[3 + index];
        const double scaled = feature * 4.0;
        if (feature < -2.0 || feature > 2.0 || scaled != std::trunc(scaled)) return -1;
    }
    int labels[4];
    for (std::size_t row = 0; row < 4; ++row) {
        const double label = input[11 + row];
        if (label < 0.0 || label > 2.0 || label != std::trunc(label)) return -1;
        labels[row] = static_cast<int>(label);
    }

    double w1[3][2];
    double w2[2][3];
    for (std::size_t i = 0; i < 3; ++i) {
        for (std::size_t j = 0; j < 2; ++j) w1[i][j] = initial_w1[i][j];
    }
    for (std::size_t j = 0; j < 2; ++j) {
        for (std::size_t k = 0; k < output_width; ++k) w2[j][k] = initial_w2[j][k];
    }

    double rates = learning_rate;
    double accuracy_history[max_epochs];
    double loss_history[max_epochs];
    for (std::size_t epoch = 0; epoch < epochs; ++epoch) {
        for (std::size_t row_index = 0; row_index < 3; ++row_index) {
            const double row[3] = {input[3 + row_index * 2], input[4 + row_index * 2], 1.0};
            double z1[2], hidden[2], prediction[3];
            forward(row, w1, w2, z1, hidden, prediction);

            double target[3];
            for (std::size_t k = 0; k < output_width; ++k) target[k] = labels[row_index] == static_cast<int>(k) ? 0.99 : 0.0;
            double delta_out[3];
            for (std::size_t k = 0; k < output_width; ++k) delta_out[k] = prediction[k] - target[k];
            double delta_hidden[2];
            for (std::size_t j = 0; j < 2; ++j) {
                delta_hidden[j] = 0.0;
                for (std::size_t k = 0; k < output_width; ++k) delta_hidden[j] += delta_out[k] * w2[j][k];
                if (z1[j] <= 0.0) delta_hidden[j] = 0.0;
            }

            for (std::size_t i = 0; i < 3; ++i) {
                for (std::size_t j = 0; j < 2; ++j) {
                    const double gradient = row[i] * delta_hidden[j];
                    w1[i][j] -= rates * gradient;
                }
            }
            for (std::size_t j = 0; j < 2; ++j) {
                for (std::size_t k = 0; k < output_width; ++k) {
                    const double gradient = hidden[j] * delta_out[k];
                    w2[j][k] -= rates * gradient;
                }
            }
        }

        const double test_row[3] = {input[9], input[10], 1.0};
        double z1[2], hidden[2], prediction[3];
        forward(test_row, w1, w2, z1, hidden, prediction);
        std::size_t predicted_class = 0;
        for (std::size_t k = 1; k < output_width; ++k) {
            if (prediction[k] > prediction[predicted_class]) predicted_class = k;
        }
        accuracy_history[epoch] = predicted_class == static_cast<std::size_t>(labels[3]) ? 1.0 : 0.0;
        double loss_sum = 0.0;
        for (std::size_t k = 0; k < output_width; ++k) {
            const double target = labels[3] == static_cast<int>(k) ? 0.99 : 0.0;
            const double difference = prediction[k] - target;
            loss_sum += difference * difference;
        }
        loss_history[epoch] = loss_sum / 2.0;
        rates *= gamma;
    }

    double staged[max_output_length];
    std::size_t result_length = 0;
    staged[result_length++] = static_cast<double>(epochs);
    double accuracy_sum = 0.0;
    for (std::size_t epoch = 0; epoch < epochs; ++epoch) {
        staged[result_length++] = accuracy_history[epoch];
        accuracy_sum += accuracy_history[epoch];
    }
    for (std::size_t epoch = 0; epoch < epochs; ++epoch) staged[result_length++] = loss_history[epoch];
    staged[result_length++] = accuracy_sum / static_cast<double>(epochs);

    if (output == nullptr || output_capacity < result_length) return -2;
    for (std::size_t index = 0; index < result_length; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(result_length);
}
