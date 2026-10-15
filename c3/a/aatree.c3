module aatree;

const int AA_MAX_OPERATIONS = 256;
struct AaNode { int key; int left; int right; int level; }

fn int node_level(AaNode* nodes, int node) {
    return node < 0 ? 0 : nodes[node].level;
}
fn int skew(AaNode* nodes, int root) {
    if (root < 0) return root;
    int left = nodes[root].left;
    if (left < 0 || nodes[left].level != nodes[root].level) return root;
    nodes[root].left = nodes[left].right;
    nodes[left].right = root;
    return left;
}
fn int split(AaNode* nodes, int root) {
    if (root < 0) return root;
    int right = nodes[root].right;
    if (right < 0) return root;
    int right_right = nodes[right].right;
    if (right_right < 0 || nodes[root].level != nodes[right_right].level) return root;
    nodes[root].right = nodes[right].left;
    nodes[right].left = root;
    nodes[right].level++;
    return right;
}
fn bool contains(AaNode* nodes, int root, int key) {
    while (root >= 0) {
        if (key < nodes[root].key) { root = nodes[root].left; }
        else if (key > nodes[root].key) { root = nodes[root].right; }
        else { return true; }
    }
    return false;
}
fn int insert_node(AaNode* nodes, int* used, int root, int key) {
    if (root < 0) {
        int fresh = *used;
        *used = *used + 1;
        nodes[fresh].key = key;
        nodes[fresh].left = -1;
        nodes[fresh].right = -1;
        nodes[fresh].level = 1;
        return fresh;
    }
    if (key < nodes[root].key) { nodes[root].left = insert_node(nodes, used, nodes[root].left, key); }
    else { nodes[root].right = insert_node(nodes, used, nodes[root].right, key); }
    return split(nodes, skew(nodes, root));
}
fn int minimum_node(AaNode* nodes, int root) {
    while (nodes[root].left >= 0) root = nodes[root].left;
    return root;
}
fn int maximum_node(AaNode* nodes, int root) {
    while (nodes[root].right >= 0) root = nodes[root].right;
    return root;
}
fn int decrease_level(AaNode* nodes, int root) {
    int left_level = node_level(nodes, nodes[root].left);
    int right_level = node_level(nodes, nodes[root].right);
    int new_level = (left_level < right_level ? left_level : right_level) + 1;
    if (new_level < nodes[root].level) {
        nodes[root].level = new_level;
        int right = nodes[root].right;
        if (right >= 0 && new_level < nodes[right].level) nodes[right].level = new_level;
    }
    return root;
}
fn int remove_node(AaNode* nodes, int root, int key) {
    if (key < nodes[root].key) { nodes[root].left = remove_node(nodes, nodes[root].left, key); }
    else if (key > nodes[root].key) { nodes[root].right = remove_node(nodes, nodes[root].right, key); }
    else if (nodes[root].left < 0 && nodes[root].right < 0) { return -1; }
    else if (nodes[root].left < 0) {
        int successor = minimum_node(nodes, nodes[root].right);
        nodes[root].key = nodes[successor].key;
        nodes[root].right = remove_node(nodes, nodes[root].right, nodes[successor].key);
    } else {
        int predecessor = maximum_node(nodes, nodes[root].left);
        nodes[root].key = nodes[predecessor].key;
        nodes[root].left = remove_node(nodes, nodes[root].left, nodes[predecessor].key);
    }
    root = skew(nodes, decrease_level(nodes, root));
    int right = nodes[root].right;
    if (right >= 0) {
        right = skew(nodes, right);
        int right_right = nodes[right].right;
        if (right_right >= 0) nodes[right].right = skew(nodes, right_right);
        nodes[root].right = right;
    }
    root = split(nodes, root);
    right = nodes[root].right;
    if (right >= 0) nodes[root].right = split(nodes, right);
    return root;
}
fn void write_i32(char* output, usz offset, int value) {
    uint bits = (uint)value;
    output[offset] = (char)bits;
    output[offset + 1] = (char)(bits >> 8);
    output[offset + 2] = (char)(bits >> 16);
    output[offset + 3] = (char)(bits >> 24);
}

fn long aatree(long* input, usz length, char* output, usz capacity) @export("aatree") {
    if (input == null || length < 1 || input[0] < 0 || input[0] > AA_MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[0];
    if (length != 1 + 2 * operation_count) return -1;
    usz output_bytes = 4 * operation_count;
    if (output_bytes > 0 && (output == null || capacity < output_bytes)) return -2;
    AaNode[AA_MAX_OPERATIONS] nodes;
    int used = 0;
    int root = -1;
    int size = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[1 + 2 * operation];
        long raw_key = input[2 + 2 * operation];
        if (opcode < 0 || opcode > 4) return -1;
        if (opcode <= 2 && (raw_key < -2147483648 || raw_key > 2147483647)) return -1;
        if (opcode >= 3 && raw_key != 0) return -1;
        int key = (int)raw_key;
        int result;
        if (opcode == 0) {
            if (contains(&nodes[0], root, key)) return -1;
            root = insert_node(&nodes[0], &used, root, key);
            size++;
            result = size;
        } else if (opcode == 1) {
            if (!contains(&nodes[0], root, key)) return -1;
            root = remove_node(&nodes[0], root, key);
            size--;
            result = size;
        } else if (opcode == 2) {
            result = contains(&nodes[0], root, key) ? 1 : 0;
        } else if (root < 0) { return -1; }
        else if (opcode == 3) { result = nodes[minimum_node(&nodes[0], root)].key; }
        else { result = nodes[maximum_node(&nodes[0], root)].key; }
        write_i32(output, 4 * operation, result);
    }
    return (long)output_bytes;
}
