#include <cstddef>
#include <cstdint>

extern "C" std::int64_t k_nn(const std::int64_t* input, std::size_t input_length) noexcept {
    constexpr std::size_t max_parseable_input_values = 300;
    constexpr std::size_t max_training_count = 32;
    constexpr std::size_t max_feature_count = 8;
    if (input == nullptr || input_length < 3 || input_length > max_parseable_input_values) return -1;

    const std::int64_t training_count_value = input[0];
    const std::int64_t feature_count_value = input[1];
    const std::int64_t neighbor_count_value = input[2];
    if (training_count_value < 1 || training_count_value > static_cast<std::int64_t>(max_training_count) ||
        feature_count_value < 1 || feature_count_value > static_cast<std::int64_t>(max_feature_count) ||
        neighbor_count_value < 1 || neighbor_count_value > training_count_value ||
        neighbor_count_value % 2 == 0) return -1;

    const std::size_t training_count = static_cast<std::size_t>(training_count_value);
    const std::size_t feature_count = static_cast<std::size_t>(feature_count_value);
    const std::size_t neighbor_count = static_cast<std::size_t>(neighbor_count_value);
    constexpr std::size_t feature_start = 3;
    const std::size_t label_start = feature_start + training_count * feature_count;
    const std::size_t query_start = label_start + training_count;
    const std::size_t expected_length = query_start + feature_count;
    if (input_length != expected_length) return -1;

    for (std::size_t index = feature_start; index < label_start; ++index) {
        if (input[index] < -32 || input[index] > 32) return -1;
    }
    for (std::size_t index = label_start; index < query_start; ++index) {
        if (input[index] != 0 && input[index] != 1) return -1;
    }
    for (std::size_t index = query_start; index < expected_length; ++index) {
        if (input[index] < -32 || input[index] > 32) return -1;
    }

    std::int64_t query_norm = 0;
    for (std::size_t feature = 0; feature < feature_count; ++feature) {
        const std::int64_t coordinate = input[query_start + feature];
        query_norm += coordinate * coordinate;
    }

    std::int64_t distances[max_training_count];
    std::size_t order[max_training_count];
    for (std::size_t row = 0; row < training_count; ++row) {
        std::int64_t row_norm = 0;
        std::int64_t cross_product = 0;
        for (std::size_t feature = 0; feature < feature_count; ++feature) {
            const std::int64_t coordinate = input[feature_start + row * feature_count + feature];
            const std::int64_t query_coordinate = input[query_start + feature];
            row_norm += coordinate * coordinate;
            cross_product += coordinate * query_coordinate;
        }
        distances[row] = query_norm - 2 * cross_product + row_norm;
        order[row] = row;
    }

    for (std::size_t left = 0; left < training_count; ++left) {
        for (std::size_t right = left + 1; right < training_count; ++right) {
            if (distances[left] == distances[right]) return -1;
        }
    }

    for (std::size_t index = 1; index < training_count; ++index) {
        const std::size_t current = order[index];
        std::size_t position = index;
        while (position > 0 && distances[order[position - 1]] > distances[current]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }

    std::size_t class_zero_votes = 0;
    std::size_t class_one_votes = 0;
    for (std::size_t index = 0; index < neighbor_count; ++index) {
        if (input[label_start + order[index]] == 0) ++class_zero_votes;
        else ++class_one_votes;
    }
    return class_one_votes > class_zero_votes ? 1 : 0;
}
