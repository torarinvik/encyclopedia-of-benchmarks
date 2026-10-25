module bisort;

const MIN_SIZE = 2;
const MAX_SIZE = 1024;
const MAX_NODES = MAX_SIZE - 1;
const MODULUS = 10000;
const MULTIPLIER = 31415821;
const RANGE = 100;

struct Node { int value; int left; int right; }

fn int multiply(int p, int q) {
    int p_high = p / MODULUS;
    int p_low = p % MODULUS;
    int q_high = q / MODULUS;
    int q_low = q % MODULUS;
    return ((p_low * q_high + p_high * q_low) % MODULUS) * MODULUS + p_low * q_low;
}

fn int next_random(int seed) { return multiply(seed, MULTIPLIER) + 1; }

fn int skip_random(int seed, int count) {
    for (int i = 0; i < count; i++) seed = next_random(seed);
    return seed;
}

fn int make_tree(Node* nodes, int* used, int size, int seed) {
    if (size <= 1) return -1;
    seed = next_random(seed);
    int index = *used;
    *used = *used + 1;
    nodes[index].value = seed % RANGE;
    int half = size / 2;
    nodes[index].left = make_tree(nodes, used, half, seed);
    nodes[index].right = make_tree(nodes, used, half, skip_random(seed, size + 1));
    return index;
}

fn void swap_left(Node* nodes, int left, int right, int left_left, int right_left,
                  int left_value, int right_value) {
    nodes[right].value = left_value;
    nodes[right].left = left_left;
    nodes[left].left = right_left;
    nodes[left].value = right_value;
}

fn void swap_right(Node* nodes, int left, int right, int left_right, int right_right,
                   int left_value, int right_value) {
    nodes[right].value = left_value;
    nodes[right].right = left_right;
    nodes[left].right = right_right;
    nodes[left].value = right_value;
}

fn int merge(Node* nodes, int root, int spill, int direction) {
    int root_value = nodes[root].value;
    int left = nodes[root].left;
    int right = nodes[root].right;
    bool right_exchange = (root_value > spill) != (direction != 0);
    if (right_exchange) {
        nodes[root].value = spill;
        spill = root_value;
    }
    while (left >= 0) {
        int left_value = nodes[left].value;
        int left_left = nodes[left].left;
        int left_right = nodes[left].right;
        int right_value = nodes[right].value;
        int right_left = nodes[right].left;
        int right_right = nodes[right].right;
        bool element_exchange = (left_value > right_value) != (direction != 0);
        if (right_exchange) {
            if (element_exchange) {
                swap_right(nodes, left, right, left_right, right_right, left_value, right_value);
                left = left_left;
                right = right_left;
            } else {
                left = left_right;
                right = right_right;
            }
        } else if (element_exchange) {
            swap_left(nodes, left, right, left_left, right_left, left_value, right_value);
            left = left_right;
            right = right_right;
        } else {
            left = left_left;
            right = right_left;
        }
    }
    if (nodes[root].left >= 0) {
        int left_root = nodes[root].left;
        int right_root = nodes[root].right;
        root_value = nodes[root].value;
        nodes[root].value = merge(nodes, left_root, root_value, direction);
        spill = merge(nodes, right_root, spill, direction);
    }
    return spill;
}

fn int sort_tree(Node* nodes, int root, int spill, int direction) {
    if (nodes[root].left < 0) {
        if ((nodes[root].value > spill) != (direction != 0)) {
            int value = nodes[root].value;
            nodes[root].value = spill;
            spill = value;
        }
        return spill;
    }
    int left = nodes[root].left;
    int right = nodes[root].right;
    int value = nodes[root].value;
    nodes[root].value = sort_tree(nodes, left, value, direction);
    spill = sort_tree(nodes, right, spill, !direction);
    return merge(nodes, root, spill, direction);
}

fn void checksum(Node* nodes, int index, long* position, long* sum) {
    if (index < 0) return;
    checksum(nodes, nodes[index].left, position, sum);
    *position = *position + 1;
    *sum = *sum + *position * nodes[index].value;
    checksum(nodes, nodes[index].right, position, sum);
}

fn long bisort(long size) @export("bisort") {
    if (size < MIN_SIZE || size > MAX_SIZE) return -1;
    Node[MAX_NODES] nodes;
    int used = 0;
    int root = make_tree(&nodes[0], &used, (int)size, 12345768);
    int spill = next_random(245867) % RANGE;
    spill = sort_tree(&nodes[0], root, spill, 0);
    spill = sort_tree(&nodes[0], root, spill, 1);
    long position = 0;
    long sum = 0;
    checksum(&nodes[0], root, &position, &sum);
    position = position + 1;
    return sum + position * spill;
}
