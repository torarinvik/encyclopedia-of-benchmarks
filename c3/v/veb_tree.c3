module veb_tree;

const usz MAX_COUNT = 256;
const usz MAX_INPUT_VALUES = 771;
const usz MAX_OUTPUT_BYTES = 1024;
const usz MAX_TREE_NODES = 358;
const usz MAX_CLUSTERS = 16;

struct VebNode {
    int universe;
    int low_bits;
    int cluster_count;
    int minimum;
    int maximum;
    int summary;
    int[MAX_CLUSTERS] clusters;
}

fn int initialize(VebNode* nodes, usz* next, int universe) {
    int id = (int)*next;
    *next = *next + 1;
    nodes[id].universe = universe;
    nodes[id].low_bits = 0;
    nodes[id].cluster_count = 0;
    nodes[id].minimum = -1;
    nodes[id].maximum = 0;
    nodes[id].summary = -1;
    if (universe > 2) {
        int exponent = 0;
        int value = universe;
        while (value > 1) {
            value /= 2;
            exponent += 1;
        }
        int low_bits = exponent / 2;
        int low_size = 1 << low_bits;
        int cluster_count = universe / low_size;
        nodes[id].low_bits = low_bits;
        nodes[id].cluster_count = cluster_count;
        nodes[id].summary = initialize(nodes, next, cluster_count);
        for (int i = 0; i < cluster_count; ++i)
            nodes[id].clusters[i] = initialize(nodes, next, low_size);
    }
    return id;
}

fn bool contains(VebNode* nodes, int id, int value) {
    if (nodes[id].minimum < 0) return false;
    if (nodes[id].minimum == value || nodes[id].maximum == value) return true;
    if (nodes[id].universe == 2) return false;
    int low_size = 1 << nodes[id].low_bits;
    int high = value >> nodes[id].low_bits;
    int low = value & (low_size - 1);
    return contains(nodes, nodes[id].clusters[high], low);
}

fn void insert(VebNode* nodes, int id, int value) {
    if (contains(nodes, id, value)) return;
    if (nodes[id].minimum < 0) {
        nodes[id].minimum = value;
        nodes[id].maximum = value;
        return;
    }
    if (value < nodes[id].minimum) {
        int old_minimum = nodes[id].minimum;
        nodes[id].minimum = value;
        value = old_minimum;
    }
    if (nodes[id].universe > 2) {
        int low_size = 1 << nodes[id].low_bits;
        int high = value >> nodes[id].low_bits;
        int low = value & (low_size - 1);
        int cluster = nodes[id].clusters[high];
        if (nodes[cluster].minimum < 0) {
            insert(nodes, nodes[id].summary, high);
            nodes[cluster].minimum = low;
            nodes[cluster].maximum = low;
        } else {
            insert(nodes, cluster, low);
        }
    }
    if (value > nodes[id].maximum) nodes[id].maximum = value;
}

fn int successor(VebNode* nodes, int id, int value) {
    if (nodes[id].minimum < 0) return -1;
    if (value < nodes[id].minimum) return nodes[id].minimum;
    if (nodes[id].universe == 2) return value == 0 && nodes[id].maximum == 1 ? 1 : -1;
    int low_size = 1 << nodes[id].low_bits;
    int high = value >> nodes[id].low_bits;
    int low = value & (low_size - 1);
    int cluster = nodes[id].clusters[high];
    if (nodes[cluster].minimum >= 0 && low < nodes[cluster].maximum) {
        int next_low = successor(nodes, cluster, low);
        if (next_low < 0) return -1;
        return high * low_size + next_low;
    }
    int next_cluster = successor(nodes, nodes[id].summary, high);
    if (next_cluster < 0) return -1;
    int next_minimum = nodes[nodes[id].clusters[next_cluster]].minimum;
    if (next_minimum < 0) return -1;
    return next_cluster * low_size + next_minimum;
}

fn int predecessor(VebNode* nodes, int id, int value) {
    if (nodes[id].minimum < 0 || value <= nodes[id].minimum) return -1;
    if (value > nodes[id].maximum) return nodes[id].maximum;
    if (nodes[id].universe == 2) return value == 1 && nodes[id].minimum == 0 ? 0 : -1;
    int low_size = 1 << nodes[id].low_bits;
    int high = value >> nodes[id].low_bits;
    int low = value & (low_size - 1);
    int cluster = nodes[id].clusters[high];
    if (nodes[cluster].minimum >= 0 && low > nodes[cluster].minimum) {
        int previous_low = predecessor(nodes, cluster, low);
        if (previous_low >= 0) return high * low_size + previous_low;
    }
    int previous_cluster = predecessor(nodes, nodes[id].summary, high);
    if (previous_cluster < 0) return nodes[id].minimum;
    int previous_maximum = nodes[nodes[id].clusters[previous_cluster]].maximum;
    if (previous_maximum < 0) return -1;
    return previous_cluster * low_size + previous_maximum;
}

fn long veb_tree(long* input, usz length, char* output, usz capacity)
        @export("veb_tree") {
    if (input == null || length < 3 || length > MAX_INPUT_VALUES + 1) return -1;
    if (input[0] < 2 || input[0] > 256 || input[1] < 0 || input[1] > (long)MAX_COUNT ||
        input[2] < 0 || input[2] > (long)MAX_COUNT) return -1;
    int requested = (int)input[0];
    usz insert_count = (usz)input[1];
    usz query_count = (usz)input[2];
    if (length != 3 + insert_count + 2 * query_count) return -1;
    for (usz i = 0; i < insert_count; ++i)
        if (input[3 + i] < 0 || input[3 + i] >= requested) return -1;
    for (usz i = 0; i < query_count; ++i) {
        long opcode = input[3 + insert_count + 2 * i];
        long key = input[4 + insert_count + 2 * i];
        if (opcode < 0 || opcode > 4 || key < 0 || key >= requested) return -1;
    }
    usz needed = query_count * 4;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < needed) return -2;

    int rounded = 1;
    while (rounded < requested) rounded *= 2;
    VebNode[MAX_TREE_NODES] nodes;
    usz next = 0;
    int root = initialize(&nodes[0], &next, rounded);
    for (usz i = 0; i < insert_count; ++i) insert(&nodes[0], root, (int)input[3 + i]);
    char[MAX_OUTPUT_BYTES] result;
    for (usz i = 0; i < query_count; ++i) {
        int opcode = (int)input[3 + insert_count + 2 * i];
        int key = (int)input[4 + insert_count + 2 * i];
        int value;
        if (opcode == 0) value = contains(&nodes[0], root, key) ? 1 : 0;
        else if (opcode == 1) value = successor(&nodes[0], root, key);
        else if (opcode == 2) value = predecessor(&nodes[0], root, key);
        else if (opcode == 3) value = nodes[root].minimum;
        else value = nodes[root].minimum < 0 ? 0 : nodes[root].maximum;
        uint bits = (uint)value;
        result[4 * i] = (char)(bits & 255);
        result[4 * i + 1] = (char)((bits >> 8) & 255);
        result[4 * i + 2] = (char)((bits >> 16) & 255);
        result[4 * i + 3] = (char)((bits >> 24) & 255);
    }
    for (usz i = 0; i < needed; ++i) output[i] = result[i];
    return (long)needed;
}
