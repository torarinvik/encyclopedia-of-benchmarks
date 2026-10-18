module perceptron_java;

const usz MAX_SAMPLES = 8;
const usz MAX_FEATURES = 4;
const usz MAX_QUERIES = 4;
const usz MAX_INPUT_LENGTH = 61;
const usz MAX_PARSEABLE_INPUT_LENGTH = 62;
const usz MAX_OUTPUT_LENGTH = 13;

bool finite_value(double value) {
    return value == value && value - value == 0.0;
}

fn long perceptron_java(double* input, usz input_length, double* output, usz output_capacity)
    @export("perceptron_java") {
    if (input == null || input_length < 9 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < input_length; index++) {
        if (!finite_value(input[index])) return -1L;
    }

    double learning_rate = input[0];
    double epochs_value = input[1];
    double samples_value = input[2];
    double features_value = input[3];
    if (learning_rate != 0.25 && learning_rate != 0.5 &&
        learning_rate != 0.75 && learning_rate != 1.0) return -1L;
    if (epochs_value < 1.0 || epochs_value > 12.0 || (double)(long)epochs_value != epochs_value ||
        samples_value < 2.0 || samples_value > (double)MAX_SAMPLES || (double)(long)samples_value != samples_value ||
        features_value < 1.0 || features_value > (double)MAX_FEATURES || (double)(long)features_value != features_value) return -1L;

    usz max_epochs = (usz)(long)epochs_value;
    usz sample_count = (usz)(long)samples_value;
    usz feature_count = (usz)(long)features_value;
    usz features_start = 4;
    usz labels_start = features_start + sample_count * feature_count;
    usz query_count_index = labels_start + sample_count;
    if (input_length <= query_count_index) return -1L;

    double query_count_value = input[query_count_index];
    if (query_count_value < 1.0 || query_count_value > (double)MAX_QUERIES ||
        (double)(long)query_count_value != query_count_value) return -1L;
    usz query_count = (usz)(long)query_count_value;
    usz query_start = query_count_index + 1;
    if (input_length != query_start + query_count * feature_count || input_length > MAX_INPUT_LENGTH) return -1L;

    for (usz row = 0; row < sample_count; row++) {
        for (usz feature = 0; feature < feature_count; feature++) {
            double value = input[features_start + row * feature_count + feature];
            if (value < -2.0 || value > 2.0 || (double)(long)value != value) return -1L;
        }
    }
    for (usz row = 0; row < sample_count; row++) {
        double label = input[labels_start + row];
        if (label != 0.0 && label != 1.0) return -1L;
    }
    for (usz row = 0; row < query_count; row++) {
        for (usz feature = 0; feature < feature_count; feature++) {
            double value = input[query_start + row * feature_count + feature];
            if (value < -2.0 || value > 2.0 || (double)(long)value != value) return -1L;
        }
    }

    double[MAX_FEATURES] weights = zeroed;
    double bias = 0.0;
    usz epochs_run = 0;
    bool converged = false;
    for (usz epoch = 0; epoch < max_epochs; epoch++) {
        bool updated = false;
        for (usz row = 0; row < sample_count; row++) {
            double weighted_sum = bias;
            for (usz feature = 0; feature < feature_count; feature++) {
                weighted_sum += weights[feature] * input[features_start + row * feature_count + feature];
            }
            long prediction = weighted_sum >= 0.0 ? 1L : 0L;
            long label = (long)input[labels_start + row];
            long error = label - prediction;
            if (error != 0) {
                for (usz feature = 0; feature < feature_count; feature++) {
                    weights[feature] += learning_rate * (double)error * input[features_start + row * feature_count + feature];
                }
                bias += learning_rate * (double)error;
                updated = true;
            }
        }
        epochs_run = epoch + 1;
        if (!updated) {
            converged = true;
            break;
        }
    }

    double[MAX_OUTPUT_LENGTH] staged = zeroed;
    usz result_length = 0;
    staged[result_length++] = (double)feature_count;
    for (usz feature = 0; feature < feature_count; feature++) staged[result_length++] = weights[feature];
    staged[result_length++] = bias;
    staged[result_length++] = (double)epochs_run;
    staged[result_length++] = converged ? 1.0 : 0.0;
    staged[result_length++] = (double)query_count;
    for (usz row = 0; row < query_count; row++) {
        double weighted_sum = bias;
        for (usz feature = 0; feature < feature_count; feature++) {
            weighted_sum += weights[feature] * input[query_start + row * feature_count + feature];
        }
        staged[result_length++] = weighted_sum >= 0.0 ? 1.0 : 0.0;
    }

    if (output == null || output_capacity < result_length) return -2L;
    for (usz index = 0; index < result_length; index++) output[index] = staged[index];
    return (long)result_length;
}
