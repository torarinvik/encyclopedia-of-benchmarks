module decision_tree_rust_id3;

const usz MAX_SAMPLES = 8;
const usz MAX_FEATURES = 4;
const usz MAX_QUERIES = 4;
const usz MAX_INPUT_LENGTH = 62;
const usz MAX_VALID_INPUT_LENGTH = 61;
const usz MAX_OUTPUT_LENGTH = 5;
const usz MAX_TREE_NODES = 2 * MAX_SAMPLES - 1;

struct TreeNode {
    double threshold;
    int feature;
    int label;
    int left;
    int right;
    bool leaf;
}

extern fn double log2(double value);
extern fn double trunc(double value);

double entropy(int* rows, usz start, usz end, int* labels) {
    double sum = 0.0;
    usz length = end - start;
    for (usz position = start; position < end; position++) {
        int label = labels[rows[position]];
        bool first = true;
        for (usz previous = start; previous < position; previous++) {
            if (labels[rows[previous]] == label) { first = false; break; }
        }
        if (!first) continue;
        usz count = 0;
        for (usz index = start; index < end; index++) {
            if (labels[rows[index]] == label) count++;
        }
        double probability = (double)count / (double)length;
        sum += probability * log2(probability);
    }
    return -sum;
}

int majority_label(int* rows, usz row_count, int* labels) {
    usz[3] counts = zeroed;
    for (usz index = 0; index < row_count; index++) counts[labels[rows[index]]]++;
    int best_label = labels[rows[0]];
    usz best_count = counts[best_label];
    for (usz index = 0; index < row_count; index++) {
        int label = labels[rows[index]];
        if (counts[label] > best_count) {
            best_label = label;
            best_count = counts[label];
        }
    }
    return best_label;
}

int build_tree(TreeNode* nodes, usz* used, double* features, int* labels,
    int* rows, usz row_count, usz feature_count, usz max_depth,
    usz min_samples_split, usz depth) {
    if (*used >= MAX_TREE_NODES || row_count == 0) return -1;
    int current = (int)(*used);
    (*used)++;
    int majority = majority_label(rows, row_count, labels);
    nodes[current] = {0.0, -1, majority, -1, -1, true};

    usz unique_labels = 0;
    bool[3] seen_labels = zeroed;
    for (usz index = 0; index < row_count; index++) {
        int label = labels[rows[index]];
        if (!seen_labels[label]) { seen_labels[label] = true; unique_labels++; }
    }
    if (unique_labels == 1 || row_count < min_samples_split || depth >= max_depth || feature_count == 0) return current;

    double parent_entropy = entropy(rows, 0, row_count, labels);
    double best_gain = 0.0;
    int best_feature = -1;
    double best_threshold = 0.0;
    int[MAX_SAMPLES] sorted_rows = zeroed;
    for (usz feature = 0; feature < feature_count; feature++) {
        for (usz index = 0; index < row_count; index++) sorted_rows[index] = rows[index];
        for (usz index = 1; index < row_count; index++) {
            int row = sorted_rows[index];
            usz position = index;
            while (position > 0 && features[(usz)sorted_rows[position - 1] * feature_count + feature] >
                                   features[(usz)row * feature_count + feature]) {
                sorted_rows[position] = sorted_rows[position - 1];
                position--;
            }
            sorted_rows[position] = row;
        }
        for (usz split = 1; split < row_count; split++) {
            double left_value = features[(usz)sorted_rows[split - 1] * feature_count + feature];
            double right_value = features[(usz)sorted_rows[split] * feature_count + feature];
            if (left_value == right_value) continue;
            double threshold = (left_value + right_value) / 2.0;
            double left_weight = (double)split / (double)row_count;
            double right_weight = (double)(row_count - split) / (double)row_count;
            double gain = parent_entropy - left_weight * entropy(&sorted_rows[0], 0, split, labels) -
                right_weight * entropy(&sorted_rows[0], split, row_count, labels);
            if (gain > best_gain) {
                best_gain = gain;
                best_feature = (int)feature;
                best_threshold = threshold;
            }
        }
    }
    if (best_feature < 0) return current;

    int[MAX_SAMPLES] left_rows = zeroed;
    int[MAX_SAMPLES] right_rows = zeroed;
    usz left_count = 0;
    usz right_count = 0;
    for (usz index = 0; index < row_count; index++) {
        int row = rows[index];
        if (features[(usz)row * feature_count + (usz)best_feature] < best_threshold)
            left_rows[left_count++] = row;
        else
            right_rows[right_count++] = row;
    }
    if (left_count == 0 || right_count == 0) return current;
    nodes[current].leaf = false;
    nodes[current].feature = best_feature;
    nodes[current].threshold = best_threshold;
    int left = build_tree(nodes, used, features, labels, &left_rows[0], left_count,
        feature_count, max_depth, min_samples_split, depth + 1);
    int right = build_tree(nodes, used, features, labels, &right_rows[0], right_count,
        feature_count, max_depth, min_samples_split, depth + 1);
    if (left < 0 || right < 0) return -1;
    nodes[current].left = left;
    nodes[current].right = right;
    return current;
}

int predict(TreeNode* nodes, int node, double* query) {
    while (!nodes[node].leaf) {
        TreeNode* current = &nodes[node];
        node = query[current.feature] < current.threshold ? current.left : current.right;
    }
    return nodes[node].label;
}

bool integer_in_range(double value, int minimum, int maximum) {
    return value == value && value >= (double)minimum && value <= (double)maximum && value == trunc(value);
}

bool finite_value(double value) {
    return value == value && value - value == 0.0;
}

bool valid_feature(double value) {
    if (!finite_value(value) || value < -4.0 || value > 4.0) return false;
    double scaled = value * 4.0;
    return scaled == trunc(scaled);
}

fn long decision_tree_rust_id3(double* input, usz input_length, double* output, usz output_capacity)
    @export("decision_tree_rust_id3") {
    if (input == null || input_length < 10 || input_length > MAX_INPUT_LENGTH) return -1L;
    for (usz index = 0; index < input_length; index++) if (!finite_value(input[index])) return -1L;
    if (!integer_in_range(input[0], 0, 6) || !integer_in_range(input[1], 2, (int)MAX_SAMPLES) ||
        !integer_in_range(input[2], 2, (int)MAX_SAMPLES) || !integer_in_range(input[3], 1, (int)MAX_FEATURES)) return -1L;
    usz max_depth = (usz)(long)input[0];
    usz min_samples_split = (usz)(long)input[1];
    usz sample_count = (usz)(long)input[2];
    usz feature_count = (usz)(long)input[3];
    usz training_start = 4;
    usz row_width = feature_count + 1;
    usz query_count_index = training_start + sample_count * row_width;
    if (input_length <= query_count_index || !integer_in_range(input[query_count_index], 1, (int)MAX_QUERIES)) return -1L;
    usz query_count = (usz)(long)input[query_count_index];
    usz query_start = query_count_index + 1;
    if (input_length != query_start + query_count * feature_count || input_length > MAX_VALID_INPUT_LENGTH) return -1L;

    double[MAX_SAMPLES * MAX_FEATURES] features = zeroed;
    int[MAX_SAMPLES] labels = zeroed;
    int[MAX_SAMPLES] rows = zeroed;
    double[MAX_QUERIES * MAX_FEATURES] queries = zeroed;
    for (usz row = 0; row < sample_count; row++) {
        rows[row] = (int)row;
        usz offset = training_start + row * row_width;
        for (usz feature = 0; feature < feature_count; feature++) {
            double value = input[offset + feature];
            if (!valid_feature(value)) return -1L;
            features[row * feature_count + feature] = value;
        }
        if (!integer_in_range(input[offset + feature_count], 0, 2)) return -1L;
        labels[row] = (int)(long)input[offset + feature_count];
    }
    for (usz row = 0; row < query_count; row++) {
        for (usz feature = 0; feature < feature_count; feature++) {
            double value = input[query_start + row * feature_count + feature];
            if (!valid_feature(value)) return -1L;
            queries[row * feature_count + feature] = value;
        }
    }

    TreeNode[MAX_TREE_NODES] nodes = zeroed;
    usz used = 0;
    int root = build_tree(&nodes[0], &used, &features[0], &labels[0], &rows[0], sample_count,
        feature_count, max_depth, min_samples_split, 0);
    if (root < 0) return -1L;
    double[MAX_OUTPUT_LENGTH] staged = zeroed;
    staged[0] = (double)query_count;
    for (usz row = 0; row < query_count; row++) {
        staged[row + 1] = (double)predict(&nodes[0], root, &queries[row * feature_count]);
    }
    if (output == null || output_capacity < query_count + 1) return -2L;
    for (usz index = 0; index < query_count + 1; index++) output[index] = staged[index];
    return (long)(query_count + 1);
}
