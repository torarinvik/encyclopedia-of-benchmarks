#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_samples = 8, max_features = 4, max_queries = 4;
constexpr std::size_t max_input_length = 62, max_valid_input_length = 61, max_output_length = 5;
constexpr std::size_t max_tree_nodes = 2 * max_samples - 1;
struct TreeNode { double threshold; int feature; int label; int left; int right; bool leaf; };

double entropy(const int* rows, std::size_t start, std::size_t end, const int* labels) noexcept {
    double sum = 0.0;
    const std::size_t length = end - start;
    for (std::size_t position = start; position < end; ++position) {
        const int label = labels[rows[position]];
        bool first = true;
        for (std::size_t previous = start; previous < position; ++previous) {
            if (labels[rows[previous]] == label) { first = false; break; }
        }
        if (!first) continue;
        std::size_t count = 0;
        for (std::size_t index = start; index < end; ++index) {
            if (labels[rows[index]] == label) ++count;
        }
        const double probability = static_cast<double>(count) / static_cast<double>(length);
        sum += probability * std::log2(probability);
    }
    return -sum;
}

int majority_label(const int* rows, std::size_t row_count, const int* labels) noexcept {
    std::size_t counts[3] = {0, 0, 0};
    for (std::size_t index = 0; index < row_count; ++index) ++counts[labels[rows[index]]];
    int best_label = labels[rows[0]];
    std::size_t best_count = counts[best_label];
    for (std::size_t index = 0; index < row_count; ++index) {
        const int label = labels[rows[index]];
        if (counts[label] > best_count) { best_label = label; best_count = counts[label]; }
    }
    return best_label;
}

int build_tree(TreeNode* nodes, std::size_t& used, const double* features, const int* labels,
    const int* rows, std::size_t row_count, std::size_t feature_count,
    std::size_t max_depth, std::size_t min_samples_split, std::size_t depth) noexcept {
    if (used >= max_tree_nodes || row_count == 0) return -1;
    const int current = static_cast<int>(used++);
    const int majority = majority_label(rows, row_count, labels);
    nodes[current] = {0.0, -1, majority, -1, -1, true};
    std::size_t unique_labels = 0;
    int seen_labels[3] = {0, 0, 0};
    for (std::size_t index = 0; index < row_count; ++index) {
        const int label = labels[rows[index]];
        if (!seen_labels[label]) { seen_labels[label] = 1; ++unique_labels; }
    }
    if (unique_labels == 1 || row_count < min_samples_split || depth >= max_depth || feature_count == 0) return current;

    const double parent_entropy = entropy(rows, 0, row_count, labels);
    double best_gain = 0.0;
    int best_feature = -1;
    double best_threshold = 0.0;
    int sorted_rows[max_samples];
    for (std::size_t feature = 0; feature < feature_count; ++feature) {
        for (std::size_t index = 0; index < row_count; ++index) sorted_rows[index] = rows[index];
        for (std::size_t index = 1; index < row_count; ++index) {
            const int row = sorted_rows[index];
            std::size_t position = index;
            while (position > 0 && features[static_cast<std::size_t>(sorted_rows[position - 1]) * feature_count + feature] >
                                      features[static_cast<std::size_t>(row) * feature_count + feature]) {
                sorted_rows[position] = sorted_rows[position - 1];
                --position;
            }
            sorted_rows[position] = row;
        }
        for (std::size_t split = 1; split < row_count; ++split) {
            const double left_value = features[static_cast<std::size_t>(sorted_rows[split - 1]) * feature_count + feature];
            const double right_value = features[static_cast<std::size_t>(sorted_rows[split]) * feature_count + feature];
            if (left_value == right_value) continue;
            const double threshold = (left_value + right_value) / 2.0;
            const double left_weight = static_cast<double>(split) / static_cast<double>(row_count);
            const double right_weight = static_cast<double>(row_count - split) / static_cast<double>(row_count);
            const double gain = parent_entropy - left_weight * entropy(sorted_rows, 0, split, labels) -
                right_weight * entropy(sorted_rows, split, row_count, labels);
            if (gain > best_gain) { best_gain = gain; best_feature = static_cast<int>(feature); best_threshold = threshold; }
        }
    }
    if (best_feature < 0) return current;

    int left_rows[max_samples], right_rows[max_samples];
    std::size_t left_count = 0, right_count = 0;
    for (std::size_t index = 0; index < row_count; ++index) {
        const int row = rows[index];
        if (features[static_cast<std::size_t>(row) * feature_count + static_cast<std::size_t>(best_feature)] < best_threshold)
            left_rows[left_count++] = row;
        else
            right_rows[right_count++] = row;
    }
    if (left_count == 0 || right_count == 0) return current;
    nodes[current].leaf = false;
    nodes[current].feature = best_feature;
    nodes[current].threshold = best_threshold;
    const int left = build_tree(nodes, used, features, labels, left_rows, left_count,
        feature_count, max_depth, min_samples_split, depth + 1);
    const int right = build_tree(nodes, used, features, labels, right_rows, right_count,
        feature_count, max_depth, min_samples_split, depth + 1);
    if (left < 0 || right < 0) return -1;
    nodes[current].left = left;
    nodes[current].right = right;
    return current;
}

int predict(const TreeNode* nodes, int node, const double* query) noexcept {
    while (!nodes[node].leaf) {
        const TreeNode& current = nodes[node];
        node = query[current.feature] < current.threshold ? current.left : current.right;
    }
    return nodes[node].label;
}

bool integer_in_range(double value, int minimum, int maximum) noexcept {
    return std::isfinite(value) && value >= static_cast<double>(minimum) &&
        value <= static_cast<double>(maximum) && value == std::trunc(value);
}
bool valid_feature(double value) noexcept {
    if (!std::isfinite(value) || value < -4.0 || value > 4.0) return false;
    const double scaled = value * 4.0;
    return scaled == std::trunc(scaled);
}
}

extern "C" std::int64_t decision_tree_rust_id3(const double* input, std::size_t input_length,
    double* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 10 || input_length > max_input_length) return -1;
    for (std::size_t index = 0; index < input_length; ++index) if (!std::isfinite(input[index])) return -1;
    if (!integer_in_range(input[0], 0, 6) || !integer_in_range(input[1], 2, static_cast<int>(max_samples)) ||
        !integer_in_range(input[2], 2, static_cast<int>(max_samples)) ||
        !integer_in_range(input[3], 1, static_cast<int>(max_features))) return -1;
    const auto max_depth = static_cast<std::size_t>(input[0]);
    const auto min_samples_split = static_cast<std::size_t>(input[1]);
    const auto sample_count = static_cast<std::size_t>(input[2]);
    const auto feature_count = static_cast<std::size_t>(input[3]);
    constexpr std::size_t training_start = 4;
    const std::size_t row_width = feature_count + 1;
    const std::size_t query_count_index = training_start + sample_count * row_width;
    if (input_length <= query_count_index || !integer_in_range(input[query_count_index], 1, static_cast<int>(max_queries))) return -1;
    const auto query_count = static_cast<std::size_t>(input[query_count_index]);
    const std::size_t query_start = query_count_index + 1;
    if (input_length != query_start + query_count * feature_count || input_length > max_valid_input_length) return -1;

    double features[max_samples * max_features]{};
    int labels[max_samples]{};
    int rows[max_samples];
    double queries[max_queries * max_features]{};
    for (std::size_t row = 0; row < sample_count; ++row) {
        rows[row] = static_cast<int>(row);
        const std::size_t offset = training_start + row * row_width;
        for (std::size_t feature = 0; feature < feature_count; ++feature) {
            const double value = input[offset + feature];
            if (!valid_feature(value)) return -1;
            features[row * feature_count + feature] = value;
        }
        if (!integer_in_range(input[offset + feature_count], 0, 2)) return -1;
        labels[row] = static_cast<int>(input[offset + feature_count]);
    }
    for (std::size_t row = 0; row < query_count; ++row) {
        for (std::size_t feature = 0; feature < feature_count; ++feature) {
            const double value = input[query_start + row * feature_count + feature];
            if (!valid_feature(value)) return -1;
            queries[row * feature_count + feature] = value;
        }
    }

    TreeNode nodes[max_tree_nodes];
    std::size_t used = 0;
    const int root = build_tree(nodes, used, features, labels, rows, sample_count, feature_count,
        max_depth, min_samples_split, 0);
    if (root < 0) return -1;
    double staged[max_output_length]{};
    staged[0] = static_cast<double>(query_count);
    for (std::size_t row = 0; row < query_count; ++row) {
        staged[row + 1] = static_cast<double>(predict(nodes, root, &queries[row * feature_count]));
    }
    if (output == nullptr || output_capacity < query_count + 1) return -2;
    for (std::size_t index = 0; index < query_count + 1; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(query_count + 1);
}
