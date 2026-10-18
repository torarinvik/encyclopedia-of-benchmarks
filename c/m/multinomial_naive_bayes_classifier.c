/* Fit and batch-predict with a bounded multinomial Naive Bayes model. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_INPUT_LENGTH 360
#define MAX_OUTPUT_BYTES 72

int64_t multinomial_naive_bayes_classifier(const int64_t *input, size_t input_length,
                                           uint8_t *output, size_t output_capacity) {
    if (!input || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1;
    int64_t fit_count_value = input[0];
    if (fit_count_value < 1 || fit_count_value > 2) return -1;
    size_t fit_count = (size_t)fit_count_value;
    size_t position = 1;
    size_t feature_width = 0;
    int64_t training_rows = 0;
    int64_t class_counts[8] = {0};
    double feature_sums[64] = {0.0};
    double class_totals[8] = {0.0};
    int64_t labels[16] = {0};
    int64_t training_features[128] = {0};

    for (size_t fit = 0; fit < fit_count; fit++) {
        if (position + 2 > input_length) return -1;
        int64_t rows_value = input[position++];
        int64_t width_value = input[position++];
        if (rows_value < 1 || rows_value > 16 || width_value < 1 || width_value > 8) return -1;
        size_t rows = (size_t)rows_value;
        size_t width = (size_t)width_value;
        if (position + rows + rows * width > input_length) return -1;
        for (size_t row = 0; row < rows; row++) {
            int64_t label = input[position++];
            if (label < 0 || label > 7) return -1;
            labels[row] = label;
        }
        for (size_t index = 0; index < rows * width; index++) {
            int64_t count = input[position++];
            if (count < 0 || count > 100) return -1;
            training_features[index / width * 8 + index % width] = count;
        }

        memset(class_counts, 0, sizeof(class_counts));
        memset(feature_sums, 0, sizeof(feature_sums));
        memset(class_totals, 0, sizeof(class_totals));
        training_rows = rows_value;
        feature_width = width;
        for (size_t row = 0; row < rows; row++) {
            size_t label = (size_t)labels[row];
            class_counts[label]++;
            for (size_t column = 0; column < width; column++) {
                double count = (double)training_features[row * 8 + column];
                feature_sums[label * 8 + column] += count;
                class_totals[label] += count;
            }
        }
    }

    if (position + 2 > input_length) return -1;
    int64_t prediction_count_value = input[position++];
    int64_t prediction_width_value = input[position++];
    if (prediction_count_value < 1 || prediction_count_value > 8 ||
        prediction_width_value < 1 || prediction_width_value > 8 ||
        (size_t)prediction_width_value != feature_width) return -1;
    size_t prediction_count = (size_t)prediction_count_value;
    size_t prediction_width = (size_t)prediction_width_value;
    if (position + prediction_count * prediction_width != input_length) return -1;
    int64_t prediction_features[64] = {0};
    for (size_t index = 0; index < prediction_count * prediction_width; index++) {
        int64_t count = input[position++];
        if (count < 0 || count > 100) return -1;
        prediction_features[index / prediction_width * 8 + index % prediction_width] = count;
    }

    int64_t predictions[8] = {0};
    for (size_t row = 0; row < prediction_count; row++) {
        double best_score = -INFINITY;
        double second_score = -INFINITY;
        int64_t best_label = -1;
        for (size_t label = 0; label < 8; label++) {
            if (class_counts[label] == 0) continue;
            double score = log((double)class_counts[label] / (double)training_rows);
            double denominator = class_totals[label] + (double)feature_width;
            for (size_t column = 0; column < feature_width; column++) {
                double likelihood = (feature_sums[label * 8 + column] + 1.0) / denominator;
                score += (double)prediction_features[row * 8 + column] * log(likelihood);
            }
            if (score > best_score) {
                second_score = best_score;
                best_score = score;
                best_label = (int64_t)label;
            } else if (score > second_score) {
                second_score = score;
            }
        }
        if (best_label < 0 || (second_score != -INFINITY && best_score - second_score < 1e-8)) return -1;
        predictions[row] = best_label;
    }

    size_t output_words = prediction_count + 1;
    size_t output_bytes = output_words * 8;
    if (!output || output_capacity < output_bytes || output_bytes > MAX_OUTPUT_BYTES) return -2;
    int64_t fields[9] = {0};
    fields[0] = prediction_count_value;
    for (size_t index = 0; index < prediction_count; index++) fields[index + 1] = predictions[index];
    for (size_t index = 0; index < output_words; index++) {
        uint64_t bits = (uint64_t)fields[index];
        for (size_t byte = 0; byte < 8; byte++) output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)output_bytes;
}
