module burstsort;

const int BURST_MAX_STRINGS = 16;
const int BURST_MAX_STRING_LENGTH = 8;
const int BURST_MAX_NODES = 129;
const int BURST_THRESHOLD = 3;
const usz BURST_MAX_INPUT_LENGTH = 145;

struct BurstNode {
    int depth;
    bool burst;
    int leaf_count;
    int terminal_count;
    int[4] children;
    int[BURST_THRESHOLD] leaf_items;
    int[BURST_MAX_STRINGS] terminal_items;
}

fn int burst_new_node(BurstNode* nodes, int* used, int depth) {
    if (used[0] >= BURST_MAX_NODES) return -1;
    int id = used[0]++;
    nodes[id].depth = depth;
    nodes[id].burst = false;
    nodes[id].leaf_count = 0;
    nodes[id].terminal_count = 0;
    for (int key = 0; key < 4; key += 1) nodes[id].children[key] = -1;
    return id;
}

fn bool burst_insert(BurstNode* nodes, int* used, int node_id, int depth,
                     int item, int* string_lengths, int* string_bytes) {
    if (string_lengths[item] == depth) {
        if (nodes[node_id].terminal_count >= BURST_MAX_STRINGS) return false;
        nodes[node_id].terminal_items[nodes[node_id].terminal_count] = item;
        nodes[node_id].terminal_count += 1;
        return true;
    }

    if (!nodes[node_id].burst && nodes[node_id].leaf_count < BURST_THRESHOLD) {
        nodes[node_id].leaf_items[nodes[node_id].leaf_count] = item;
        nodes[node_id].leaf_count += 1;
        return true;
    }

    if (!nodes[node_id].burst) {
        int[BURST_THRESHOLD] saved;
        int saved_count = nodes[node_id].leaf_count;
        for (int i = 0; i < saved_count; i += 1) saved[i] = nodes[node_id].leaf_items[i];
        nodes[node_id].leaf_count = 0;
        nodes[node_id].burst = true;
        for (int i = 0; i < saved_count; i += 1) {
            if (!burst_insert(nodes, used, node_id, depth, saved[i],
                              string_lengths, string_bytes)) return false;
        }
    }

    int key = string_bytes[item * BURST_MAX_STRING_LENGTH + depth];
    if (nodes[node_id].children[key] < 0) {
        int child = burst_new_node(nodes, used, depth + 1);
        if (child < 0) return false;
        nodes[node_id].children[key] = child;
    }
    return burst_insert(nodes, used, nodes[node_id].children[key], depth + 1,
                        item, string_lengths, string_bytes);
}

fn bool burst_string_less(int left, int right, int* string_lengths,
                          int* string_bytes) {
    int left_length = string_lengths[left];
    int right_length = string_lengths[right];
    int common = left_length < right_length ? left_length : right_length;
    for (int i = 0; i < common; i += 1) {
        int a = string_bytes[left * BURST_MAX_STRING_LENGTH + i];
        int b = string_bytes[right * BURST_MAX_STRING_LENGTH + i];
        if (a != b) return a < b;
    }
    return left_length < right_length;
}

fn void burst_emit(BurstNode* nodes, int node_id, int* output,
                   int* output_count, int* string_lengths, int* string_bytes) {
    for (int i = 0; i < nodes[node_id].terminal_count; i += 1) {
        output[output_count[0]] = nodes[node_id].terminal_items[i];
        output_count[0] += 1;
    }
    if (nodes[node_id].burst) {
        for (int key = 0; key < 4; key += 1) {
            int child = nodes[node_id].children[key];
            if (child >= 0) burst_emit(nodes, child, output, output_count,
                                       string_lengths, string_bytes);
        }
        return;
    }

    int[BURST_THRESHOLD] ordered;
    for (int i = 0; i < nodes[node_id].leaf_count; i += 1)
        ordered[i] = nodes[node_id].leaf_items[i];
    for (int i = 1; i < nodes[node_id].leaf_count; i += 1) {
        int item = ordered[i];
        int position = i;
        while (position > 0 && burst_string_less(item, ordered[position - 1],
                                                  string_lengths, string_bytes)) {
            ordered[position] = ordered[position - 1];
            position -= 1;
        }
        ordered[position] = item;
    }
    for (int i = 0; i < nodes[node_id].leaf_count; i += 1) {
        output[output_count[0]] = ordered[i];
        output_count[0] += 1;
    }
}

fn long burstsort(long* input, usz length) @export("burstsort") {
    if (input == null || length < 1 || length > BURST_MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > BURST_MAX_STRINGS) return -1;
    int count = (int)input[0];
    int[BURST_MAX_STRINGS] string_lengths = {0};
    int[BURST_MAX_STRINGS * BURST_MAX_STRING_LENGTH] string_bytes = {0};

    usz cursor = 1;
    for (int item = 0; item < count; item += 1) {
        if (cursor >= length) return -1;
        long raw_length = input[cursor++];
        if (raw_length < 0 || raw_length > BURST_MAX_STRING_LENGTH) return -1;
        int string_length = (int)raw_length;
        if ((usz)string_length > length - cursor) return -1;
        string_lengths[item] = string_length;
        for (int j = 0; j < string_length; j += 1) {
            long byte = input[cursor++];
            if (byte < 0 || byte > 3) return -1;
            string_bytes[item * BURST_MAX_STRING_LENGTH + j] = (int)byte;
        }
    }
    if (cursor != length) return -1;

    BurstNode[BURST_MAX_NODES] nodes = zeroed;
    int used = 0;
    int root = burst_new_node(&nodes[0], &used, 0);
    if (root < 0) return -1;
    for (int item = 0; item < count; item += 1) {
        if (!burst_insert(&nodes[0], &used, root, 0, item,
                          &string_lengths[0], &string_bytes[0])) return -1;
    }

    int[BURST_MAX_STRINGS] sorted = {0};
    int sorted_count = 0;
    burst_emit(&nodes[0], root, &sorted[0], &sorted_count,
               &string_lengths[0], &string_bytes[0]);
    if (sorted_count != count) return -1;

    long[8] powers = {78125, 15625, 3125, 625, 125, 25, 5, 1};
    long checksum = 0;
    for (int rank = 0; rank < count; rank += 1) {
        int item = sorted[rank];
        long key = 0;
        for (int j = 0; j < string_lengths[item]; j += 1) {
            key += (long)(string_bytes[item * BURST_MAX_STRING_LENGTH + j] + 1) * powers[j];
        }
        checksum += (long)(rank + 1) * key;
    }
    return checksum;
}
