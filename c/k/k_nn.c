#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_VALUES 300
#define MAX_TRAINING_COUNT 32
#define MAX_FEATURE_COUNT 8
#define MIN_FEATURE_VALUE (-32)
#define MAX_FEATURE_VALUE 32
#define INVALID_RESULT (-1)

int64_t k_nn(const int64_t *input, size_t input_length)
{
    if (input == NULL || input_length < 3 ||
        input_length > MAX_PARSEABLE_INPUT_VALUES) return INVALID_RESULT;

    const int64_t training_count_value = input[0];
    const int64_t feature_count_value = input[1];
    const int64_t neighbor_count_value = input[2];
    if (training_count_value < 1 || training_count_value > MAX_TRAINING_COUNT ||
        feature_count_value < 1 || feature_count_value > MAX_FEATURE_COUNT ||
        neighbor_count_value < 1 || neighbor_count_value > training_count_value ||
        (neighbor_count_value & 1) == 0) return INVALID_RESULT;

    const size_t training_count = (size_t)training_count_value;
    const size_t feature_count = (size_t)feature_count_value;
    const size_t neighbor_count = (size_t)neighbor_count_value;
    const size_t feature_start = 3;
    const size_t label_start = feature_start + training_count * feature_count;
    const size_t query_start = label_start + training_count;
    const size_t expected_length = query_start + feature_count;
    if (input_length != expected_length) return INVALID_RESULT;

    for (size_t index = feature_start; index < label_start; ++index) {
        if (input[index] < MIN_FEATURE_VALUE || input[index] > MAX_FEATURE_VALUE)
            return INVALID_RESULT;
    }
    for (size_t index = label_start; index < query_start; ++index) {
        if (input[index] != 0 && input[index] != 1) return INVALID_RESULT;
    }
    for (size_t index = query_start; index < expected_length; ++index) {
        if (input[index] < MIN_FEATURE_VALUE || input[index] > MAX_FEATURE_VALUE)
            return INVALID_RESULT;
    }

    int64_t query_norm = 0;
    for (size_t feature = 0; feature < feature_count; ++feature) {
        const int64_t coordinate = input[query_start + feature];
        query_norm += coordinate * coordinate;
    }

    int64_t distances[MAX_TRAINING_COUNT];
    size_t order[MAX_TRAINING_COUNT];
    for (size_t row = 0; row < training_count; ++row) {
        int64_t row_norm = 0;
        int64_t cross_product = 0;
        for (size_t feature = 0; feature < feature_count; ++feature) {
            const int64_t coordinate = input[feature_start + row * feature_count + feature];
            const int64_t query_coordinate = input[query_start + feature];
            row_norm += coordinate * coordinate;
            cross_product += coordinate * query_coordinate;
        }
        distances[row] = query_norm - 2 * cross_product + row_norm;
        order[row] = row;
    }

    for (size_t left = 0; left < training_count; ++left) {
        for (size_t right = left + 1; right < training_count; ++right) {
            if (distances[left] == distances[right]) return INVALID_RESULT;
        }
    }

    for (size_t index = 1; index < training_count; ++index) {
        const size_t current = order[index];
        size_t position = index;
        while (position > 0 && distances[order[position - 1]] > distances[current]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }

    size_t class_zero_votes = 0;
    size_t class_one_votes = 0;
    for (size_t index = 0; index < neighbor_count; ++index) {
        if (input[label_start + order[index]] == 0) ++class_zero_votes;
        else ++class_one_votes;
    }
    return class_one_votes > class_zero_votes ? 1 : 0;
}
