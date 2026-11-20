module persistent_leftist_heap;

const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 193;
const int MAX_NODES = 1024;
const int MAX_HEAP_SIZE = 128;
const long EMPTY_RANK = 20001;

struct PlhNode { long key; int left; int right; int npl; }

fn int allocate_node(PlhNode* nodes, int* used, long key, int left, int right, int npl) {
    if (used[0] >= MAX_NODES) return -1;
    int node = used[0]++;
    nodes[node].key = key;
    nodes[node].left = left;
    nodes[node].right = right;
    nodes[node].npl = npl;
    return node;
}

fn int meld(PlhNode* nodes, int* used, int left_root, int right_root) {
    if (left_root < 0 || right_root < 0) return -1;
    if (left_root == 0) return right_root;
    if (right_root == 0) return left_root;
    if (nodes[left_root].key > nodes[right_root].key) {
        int temporary = left_root;
        left_root = right_root;
        right_root = temporary;
    }

    long key = nodes[left_root].key;
    int left = nodes[left_root].left;
    int right = nodes[left_root].right;
    int npl = nodes[left_root].npl;
    int copy = allocate_node(nodes, used, key, left, right, npl);
    if (copy < 0) return -1;
    int merged_right = meld(nodes, used, right, right_root);
    if (merged_right < 0) return -1;
    nodes[copy].right = merged_right;
    if (nodes[nodes[copy].left].npl < nodes[nodes[copy].right].npl) {
        int temporary = nodes[copy].left;
        nodes[copy].left = nodes[copy].right;
        nodes[copy].right = temporary;
    }
    nodes[copy].npl = nodes[nodes[copy].right].npl + 1;
    return copy;
}

fn long persistent_leftist_heap(long* input, usz length)
        @export("persistent_leftist_heap") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_operations = input[0];
    if (raw_operations < 0 || raw_operations > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)raw_operations;

    PlhNode[MAX_NODES] nodes = zeroed;
    nodes[0].npl = -1;
    int used = 1;
    int[MAX_OPERATIONS + 1] roots = zeroed;
    int[MAX_OPERATIONS + 1] sizes = zeroed;
    long observation_sum = 0;
    long observation_xor = 0;
    usz cursor = 1;

    for (usz operation_index = 0; operation_index < operation_count; operation_index++) {
        if (cursor >= length) return -1;
        long operation = input[cursor++];
        long first;
        long second = 0;
        if (operation == 0 || operation == 1) {
            if (length - cursor < 2) return -1;
            first = input[cursor++];
            second = input[cursor++];
        } else if (operation == 2 || operation == 3) {
            if (length - cursor < 1) return -1;
            first = input[cursor++];
        } else return -1;

        int new_root = 0;
        int new_size = 0;
        if (operation == 0) {
            if (first < 0 || first > (long)operation_index || second < -10000 || second > 10000)
                return -1;
            int base = (int)first;
            if (sizes[base] >= MAX_HEAP_SIZE) return -1;
            int singleton = allocate_node(&nodes[0], &used, second, 0, 0, 0);
            if (singleton < 0) return -1;
            new_root = meld(&nodes[0], &used, roots[base], singleton);
            if (new_root < 0) return -1;
            new_size = sizes[base] + 1;
        } else if (operation == 1) {
            if (first < 0 || first > (long)operation_index ||
                second < 0 || second > (long)operation_index) return -1;
            int left_version = (int)first;
            int right_version = (int)second;
            new_size = sizes[left_version] + sizes[right_version];
            if (new_size > MAX_HEAP_SIZE) return -1;
            new_root = meld(&nodes[0], &used, roots[left_version], roots[right_version]);
            if (new_root < 0) return -1;
        } else {
            if (first < 0 || first > (long)operation_index) return -1;
            int version = (int)first;
            int root = roots[version];
            long rank = root == 0 ? EMPTY_RANK : nodes[root].key + 10000;
            observation_sum += rank;
            observation_xor ^= rank;
            if (operation == 3) {
                new_root = root;
                new_size = sizes[version];
            } else if (root != 0) {
                new_root = meld(&nodes[0], &used, nodes[root].left, nodes[root].right);
                if (new_root < 0) return -1;
                new_size = sizes[version] - 1;
            }
        }

        if (new_size > MAX_HEAP_SIZE) return -1;
        roots[operation_index + 1] = new_root;
        sizes[operation_index + 1] = new_size;
    }
    if (cursor != length) return -1;
    return (observation_sum << 15) | observation_xor;
}
