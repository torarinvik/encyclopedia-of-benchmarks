#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 8u
#define MAX_FEATURES 4u
#define MAX_QUERIES 4u
#define MAX_INPUT_LENGTH 62u
#define MAX_VALID_INPUT_LENGTH 61u
#define MAX_OUTPUT_LENGTH 5u
#define MAX_TREE_NODES (2u * MAX_SAMPLES - 1u)

typedef struct {
    double threshold;
    int feature;
    int label;
    int left;
    int right;
    int leaf;
} TreeNode;

static double entropy(const int *rows, size_t start, size_t end, const int *labels) {
    double sum = 0.0;
    const size_t length = end - start;
    for (size_t position = start; position < end; ++position) {
        const int label = labels[rows[position]];
        int first = 1;
        for (size_t previous = start; previous < position; ++previous) {
            if (labels[rows[previous]] == label) { first = 0; break; }
        }
        if (!first) continue;
        size_t count = 0;
        for (size_t index = start; index < end; ++index) {
            if (labels[rows[index]] == label) ++count;
        }
        const double probability = (double)count / (double)length;
        sum += probability * log2(probability);
    }
    return -sum;
}

static int majority_label(const int *rows, size_t row_count, const int *labels) {
    size_t counts[3] = {0, 0, 0};
    for (size_t index = 0; index < row_count; ++index) ++counts[labels[rows[index]]];
    int best_label = labels[rows[0]];
    size_t best_count = counts[best_label];
    for (size_t index = 0; index < row_count; ++index) {
        const int label = labels[rows[index]];
        if (counts[label] > best_count) {
            best_label = label;
            best_count = counts[label];
        }
    }
    return best_label;
}

static int build_tree(TreeNode *nodes, size_t *used, const double *features, const int *labels,
                      const int *rows, size_t row_count, size_t feature_count,
                      size_t max_depth, size_t min_samples_split, size_t depth) {
    if (*used >= MAX_TREE_NODES || row_count == 0) return -1;
    const int current = (int)(*used)++;
    const int majority = majority_label(rows, row_count, labels);
    nodes[current] = (TreeNode){0.0, -1, majority, -1, -1, 1};

    size_t unique_labels = 0;
    int seen_labels[3] = {0, 0, 0};
    for (size_t index = 0; index < row_count; ++index) {
        const int label = labels[rows[index]];
        if (!seen_labels[label]) { seen_labels[label] = 1; ++unique_labels; }
    }
    if (unique_labels == 1 || row_count < min_samples_split || depth >= max_depth || feature_count == 0) return current;

    const double parent_entropy = entropy(rows, 0, row_count, labels);
    double best_gain = 0.0;
    int best_feature = -1;
    double best_threshold = 0.0;
    int sorted_rows[MAX_SAMPLES];
    for (size_t feature = 0; feature < feature_count; ++feature) {
        for (size_t index = 0; index < row_count; ++index) sorted_rows[index] = rows[index];
        for (size_t index = 1; index < row_count; ++index) {
            const int row = sorted_rows[index];
            size_t position = index;
            while (position > 0 && features[(size_t)sorted_rows[position - 1] * feature_count + feature] >
                                      features[(size_t)row * feature_count + feature]) {
                sorted_rows[position] = sorted_rows[position - 1];
                --position;
            }
            sorted_rows[position] = row;
        }
        for (size_t split = 1; split < row_count; ++split) {
            const double left_value = features[(size_t)sorted_rows[split - 1] * feature_count + feature];
            const double right_value = features[(size_t)sorted_rows[split] * feature_count + feature];
            if (left_value == right_value) continue;
            const double threshold = (left_value + right_value) / 2.0;
            const double left_weight = (double)split / (double)row_count;
            const double right_weight = (double)(row_count - split) / (double)row_count;
            const double gain = parent_entropy - left_weight * entropy(sorted_rows, 0, split, labels) -
                right_weight * entropy(sorted_rows, split, row_count, labels);
            if (gain > best_gain) {
                best_gain = gain;
                best_feature = (int)feature;
                best_threshold = threshold;
            }
        }
    }
    if (best_feature < 0) return current;

    int left_rows[MAX_SAMPLES], right_rows[MAX_SAMPLES];
    size_t left_count = 0, right_count = 0;
    for (size_t index = 0; index < row_count; ++index) {
        const int row = rows[index];
        if (features[(size_t)row * feature_count + (size_t)best_feature] < best_threshold)
            left_rows[left_count++] = row;
        else
            right_rows[right_count++] = row;
    }
    if (left_count == 0 || right_count == 0) return current;
    nodes[current].leaf = 0;
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

static int predict(const TreeNode *nodes, int node, const double *query) {
    while (!nodes[node].leaf) {
        const TreeNode *current = &nodes[node];
        node = query[(size_t)current->feature] < current->threshold ? current->left : current->right;
    }
    return nodes[node].label;
}

static int integer_in_range(double value, int minimum, int maximum) {
    return isfinite(value) && value >= (double)minimum && value <= (double)maximum && value == trunc(value);
}

static int valid_feature(double value) {
    if (!isfinite(value) || value < -4.0 || value > 4.0) return 0;
    const double scaled = value * 4.0;
    return scaled == trunc(scaled);
}

int64_t decision_tree_rust_id3(const double *input, size_t input_length,
                               double *output, size_t output_capacity) {
    if (input == NULL || input_length < 10u || input_length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < input_length; ++index) if (!isfinite(input[index])) return -1;
    if (!integer_in_range(input[0], 0, 6) || !integer_in_range(input[1], 2, 8) ||
        !integer_in_range(input[2], 2, (int)MAX_SAMPLES) || !integer_in_range(input[3], 1, (int)MAX_FEATURES)) return -1;
    const size_t max_depth = (size_t)input[0];
    const size_t min_samples_split = (size_t)input[1];
    const size_t sample_count = (size_t)input[2];
    const size_t feature_count = (size_t)input[3];
    const size_t training_start = 4;
    const size_t row_width = feature_count + 1;
    const size_t query_count_index = training_start + sample_count * row_width;
    if (input_length <= query_count_index || !integer_in_range(input[query_count_index], 1, (int)MAX_QUERIES)) return -1;
    const size_t query_count = (size_t)input[query_count_index];
    const size_t query_start = query_count_index + 1;
    if (input_length != query_start + query_count * feature_count || input_length > MAX_VALID_INPUT_LENGTH) return -1;

    double features[MAX_SAMPLES * MAX_FEATURES] = {0.0};
    int labels[MAX_SAMPLES] = {0};
    int rows[MAX_SAMPLES];
    double queries[MAX_QUERIES * MAX_FEATURES] = {0.0};
    for (size_t row = 0; row < sample_count; ++row) {
        rows[row] = (int)row;
        const size_t offset = training_start + row * row_width;
        for (size_t feature = 0; feature < feature_count; ++feature) {
            const double value = input[offset + feature];
            if (!valid_feature(value)) return -1;
            features[row * feature_count + feature] = value;
        }
        if (!integer_in_range(input[offset + feature_count], 0, 2)) return -1;
        labels[row] = (int)input[offset + feature_count];
    }
    for (size_t row = 0; row < query_count; ++row) {
        for (size_t feature = 0; feature < feature_count; ++feature) {
            const double value = input[query_start + row * feature_count + feature];
            if (!valid_feature(value)) return -1;
            queries[row * feature_count + feature] = value;
        }
    }

    TreeNode nodes[MAX_TREE_NODES];
    size_t used = 0;
    const int root = build_tree(nodes, &used, features, labels, rows, sample_count, feature_count,
                                max_depth, min_samples_split, 0);
    if (root < 0) return -1;
    double staged[MAX_OUTPUT_LENGTH] = {0.0};
    staged[0] = (double)query_count;
    for (size_t row = 0; row < query_count; ++row) {
        staged[row + 1] = (double)predict(nodes, root, &queries[row * feature_count]);
    }
    if (output == NULL || output_capacity < query_count + 1) return -2;
    for (size_t index = 0; index < query_count + 1; ++index) output[index] = staged[index];
    return (int64_t)(query_count + 1);
}
