/* Fit and batch-predict with a bounded multinomial Naive Bayes model. */
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t multinomial_naive_bayes_classifier(
    const std::int64_t *input, std::size_t input_length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (!input || input_length < 1 || input_length > 360) return -1;
    const std::int64_t fit_count_value = input[0];
    if (fit_count_value < 1 || fit_count_value > 2) return -1;
    const std::size_t fit_count = static_cast<std::size_t>(fit_count_value);
    std::size_t position = 1;
    std::size_t feature_width = 0;
    std::int64_t training_rows = 0;
    std::int64_t class_counts[8] = {};
    double feature_sums[64] = {};
    double class_totals[8] = {};
    std::int64_t labels[16] = {};
    std::int64_t training_features[128] = {};

    for (std::size_t fit = 0; fit < fit_count; fit++) {
        if (position + 2 > input_length) return -1;
        const std::int64_t rows_value = input[position++];
        const std::int64_t width_value = input[position++];
        if (rows_value < 1 || rows_value > 16 || width_value < 1 || width_value > 8) return -1;
        const std::size_t rows = static_cast<std::size_t>(rows_value);
        const std::size_t width = static_cast<std::size_t>(width_value);
        if (position + rows + rows * width > input_length) return -1;
        for (std::size_t row = 0; row < rows; row++) {
            const std::int64_t label = input[position++];
            if (label < 0 || label > 7) return -1;
            labels[row] = label;
        }
        for (std::size_t index = 0; index < rows * width; index++) {
            const std::int64_t count = input[position++];
            if (count < 0 || count > 100) return -1;
            training_features[index / width * 8 + index % width] = count;
        }

        for (std::size_t label = 0; label < 8; label++) {
            class_counts[label] = 0;
            class_totals[label] = 0.0;
        }
        for (std::size_t index = 0; index < 64; index++) feature_sums[index] = 0.0;
        training_rows = rows_value;
        feature_width = width;
        for (std::size_t row = 0; row < rows; row++) {
            const std::size_t label = static_cast<std::size_t>(labels[row]);
            class_counts[label]++;
            for (std::size_t column = 0; column < width; column++) {
                const double count = static_cast<double>(training_features[row * 8 + column]);
                feature_sums[label * 8 + column] += count;
                class_totals[label] += count;
            }
        }
    }

    if (position + 2 > input_length) return -1;
    const std::int64_t prediction_count_value = input[position++];
    const std::int64_t prediction_width_value = input[position++];
    if (prediction_count_value < 1 || prediction_count_value > 8 ||
        prediction_width_value < 1 || prediction_width_value > 8 ||
        static_cast<std::size_t>(prediction_width_value) != feature_width) return -1;
    const std::size_t prediction_count = static_cast<std::size_t>(prediction_count_value);
    const std::size_t prediction_width = static_cast<std::size_t>(prediction_width_value);
    if (position + prediction_count * prediction_width != input_length) return -1;
    std::int64_t prediction_features[64] = {};
    for (std::size_t index = 0; index < prediction_count * prediction_width; index++) {
        const std::int64_t count = input[position++];
        if (count < 0 || count > 100) return -1;
        prediction_features[index / prediction_width * 8 + index % prediction_width] = count;
    }

    std::int64_t predictions[8] = {};
    for (std::size_t row = 0; row < prediction_count; row++) {
        double best_score = -INFINITY;
        double second_score = -INFINITY;
        std::int64_t best_label = -1;
        for (std::size_t label = 0; label < 8; label++) {
            if (class_counts[label] == 0) continue;
            double score = std::log(static_cast<double>(class_counts[label]) / static_cast<double>(training_rows));
            const double denominator = class_totals[label] + static_cast<double>(feature_width);
            for (std::size_t column = 0; column < feature_width; column++) {
                const double likelihood = (feature_sums[label * 8 + column] + 1.0) / denominator;
                score += static_cast<double>(prediction_features[row * 8 + column]) * std::log(likelihood);
            }
            if (score > best_score) {
                second_score = best_score;
                best_score = score;
                best_label = static_cast<std::int64_t>(label);
            } else if (score > second_score) {
                second_score = score;
            }
        }
        if (best_label < 0 || (second_score != -INFINITY && best_score - second_score < 1e-8)) return -1;
        predictions[row] = best_label;
    }

    const std::size_t output_words = prediction_count + 1;
    const std::size_t output_bytes = output_words * 8;
    if (!output || output_capacity < output_bytes || output_bytes > 72) return -2;
    std::int64_t fields[9] = {};
    fields[0] = prediction_count_value;
    for (std::size_t index = 0; index < prediction_count; index++) fields[index + 1] = predictions[index];
    for (std::size_t index = 0; index < output_words; index++) {
        const std::uint64_t bits = static_cast<std::uint64_t>(fields[index]);
        for (std::size_t byte = 0; byte < 8; byte++) output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(output_bytes);
}
