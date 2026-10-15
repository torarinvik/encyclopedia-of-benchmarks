module avltree_unique_key_ops;

const usz MAX_NODES = 128;
const usz MAX_OPS = 128;
struct Node { long key; int left; int right; int height; }

fn int height(Node* nodes, int index) { return index < 0 ? 0 : nodes[index].height; }
fn void update(Node* nodes, int index) {
    int left = height(nodes, nodes[index].left), right = height(nodes, nodes[index].right);
    nodes[index].height = 1 + (left > right ? left : right);
}
fn int rotate_right(Node* nodes, int root) {
    int pivot = nodes[root].left, middle = nodes[pivot].right;
    nodes[pivot].right = root; nodes[root].left = middle;
    update(nodes, root); update(nodes, pivot); return pivot;
}
fn int rotate_left(Node* nodes, int root) {
    int pivot = nodes[root].right, middle = nodes[pivot].left;
    nodes[pivot].left = root; nodes[root].right = middle;
    update(nodes, root); update(nodes, pivot); return pivot;
}
fn int rebalance(Node* nodes, int root) {
    if (root < 0) return root;
    update(nodes, root);
    int balance = height(nodes, nodes[root].left) - height(nodes, nodes[root].right);
    if (balance > 1) {
        int left = nodes[root].left;
        if (height(nodes, nodes[left].right) > height(nodes, nodes[left].left)) nodes[root].left = rotate_left(nodes, left);
        return rotate_right(nodes, root);
    }
    if (balance < -1) {
        int right = nodes[root].right;
        if (height(nodes, nodes[right].left) > height(nodes, nodes[right].right)) nodes[root].right = rotate_right(nodes, right);
        return rotate_left(nodes, root);
    }
    return root;
}
fn int insert_node(Node* nodes, int root, long key, int* next) {
    if (root < 0) { int index = *next; *next = *next + 1; nodes[index] = {key, -1, -1, 1}; return index; }
    if (key < nodes[root].key) nodes[root].left = insert_node(nodes, nodes[root].left, key, next);
    else nodes[root].right = insert_node(nodes, nodes[root].right, key, next);
    return rebalance(nodes, root);
}
fn bool contains(Node* nodes, int root, long key) {
    while (root >= 0) { if (nodes[root].key == key) return true; root = key < nodes[root].key ? nodes[root].left : nodes[root].right; }
    return false;
}
fn int maximum_node(Node* nodes, int root) { while (nodes[root].right >= 0) root = nodes[root].right; return root; }
fn int delete_node(Node* nodes, int root, long key) {
    if (key < nodes[root].key) nodes[root].left = delete_node(nodes, nodes[root].left, key);
    else if (key > nodes[root].key) nodes[root].right = delete_node(nodes, nodes[root].right, key);
    else {
        if (nodes[root].left < 0) return nodes[root].right;
        if (nodes[root].right < 0) return nodes[root].left;
        int predecessor = maximum_node(nodes, nodes[root].left);
        nodes[root].key = nodes[predecessor].key;
        nodes[root].left = delete_node(nodes, nodes[root].left, nodes[predecessor].key);
    }
    return rebalance(nodes, root);
}
fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long avltree_unique_key_ops(long* input, usz length, char* output, usz capacity)
    @export("avltree_unique_key_ops") {
    if (input == null || length < 1) return -1;
    long operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > (long)MAX_OPS || length != (usz)(1 + 2 * operation_count_value)) return -1;
    usz operation_count = (usz)operation_count_value;
    long[MAX_NODES] active;
    usz active_count = 0, search_count = 0;
    for (usz index = 0; index < operation_count; index++) {
        long operation = input[1 + 2 * index], key = input[2 + 2 * index];
        if (operation < 0 || operation > 2 || key < -1000000 || key > 1000000) return -1;
        usz found = active_count;
        for (usz i = 0; i < active_count; i++) if (active[i] == key) { found = i; break; }
        if (operation == 0) {
            if (found != active_count || active_count >= MAX_NODES) return -1;
            active[active_count++] = key;
        } else if (operation == 1) search_count++;
        else {
            if (found == active_count) return -1;
            for (usz i = found + 1; i < active_count; i++) active[i - 1] = active[i];
            active_count--;
        }
    }
    Node[MAX_NODES] nodes;
    for (usz i = 0; i < MAX_NODES; i++) { nodes[i].left = -1; nodes[i].right = -1; nodes[i].height = 0; }
    int root = -1, next = 0;
    long[MAX_OPS] results;
    usz result_count = 0;
    for (usz index = 0; index < operation_count; index++) {
        long operation = input[1 + 2 * index], key = input[2 + 2 * index];
        if (operation == 0) root = insert_node(&nodes, root, key, &next);
        else if (operation == 1) results[result_count++] = contains(&nodes, root, key) ? 1 : 0;
        else root = delete_node(&nodes, root, key);
    }
    usz bytes = (2 + active_count + search_count) * 8;
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, (long)active_count);
    int[MAX_NODES] stack;
    usz top = 0, out = 1;
    int current = root;
    while (current >= 0 || top > 0) {
        while (current >= 0) { stack[top++] = current; current = nodes[current].left; }
        current = stack[--top]; put_i64(output, out++ * 8, nodes[current].key); current = nodes[current].right;
    }
    put_i64(output, out++ * 8, (long)search_count);
    for (usz i = 0; i < search_count; i++) put_i64(output, out++ * 8, results[i]);
    return (long)bytes;
}
