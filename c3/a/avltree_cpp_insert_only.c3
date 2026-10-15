module avltree_cpp_insert_only;

const usz MAX_NODES = 256;

fn int avl_height(int root, int* left, int* right) {
    if (root < 0) return 0;
    int left_height = avl_height(left[root], left, right);
    int right_height = avl_height(right[root], left, right);
    return 1 + (left_height > right_height ? left_height : right_height);
}

fn int avl_balance(int root, int* left, int* right) {
    return avl_height(left[root], left, right) - avl_height(right[root], left, right);
}

fn int rotate_right(int root, int* left, int* right) {
    int pivot = left[root];
    int moved = right[pivot];
    right[pivot] = root;
    left[root] = moved;
    return pivot;
}

fn int rotate_left(int root, int* left, int* right) {
    int pivot = right[root];
    int moved = left[pivot];
    left[pivot] = root;
    right[root] = moved;
    return pivot;
}

fn int insert_node(int root, int key, int* keys, int* left, int* right, usz* next_node) {
    if (root < 0) {
        int node = (int)(*next_node);
        *next_node = *next_node + 1;
        keys[node] = key;
        left[node] = -1;
        right[node] = -1;
        return node;
    }
    if (key < keys[root]) left[root] = insert_node(left[root], key, keys, left, right, next_node);
    else right[root] = insert_node(right[root], key, keys, left, right, next_node);

    int balance = avl_balance(root, left, right);
    if (balance > 1) {
        if (avl_balance(left[root], left, right) < 0)
            left[root] = rotate_left(left[root], left, right);
        return rotate_right(root, left, right);
    }
    if (balance < -1) {
        if (avl_balance(right[root], left, right) > 0)
            right[root] = rotate_right(right[root], left, right);
        return rotate_left(root, left, right);
    }
    return root;
}

fn void store_i32_le(char* output, usz position, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) output[position * 4 + byte] = (char)(bits >> (8 * byte));
}

fn void emit_inorder(int root, int* keys, int* left, int* right, char* output, usz* position) {
    if (root < 0) return;
    emit_inorder(left[root], keys, left, right, output, position);
    store_i32_le(output, *position, keys[root]);
    *position = *position + 1;
    emit_inorder(right[root], keys, left, right, output, position);
}

fn long avltree_cpp_insert_only(long* input, usz length, char* output, usz output_capacity)
    @export("avltree_cpp_insert_only") {
    if (input == null || length < 2 || length > MAX_NODES + 1) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_NODES) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;
    for (usz index = 0; index < count; index++) {
        long key = input[index + 1];
        if (key < -2147483648 || key > 2147483647) return -1;
        for (usz previous = 0; previous < index; previous++)
            if (input[previous + 1] == key) return -1;
    }
    usz required = count * 4;
    if (output == null || output_capacity < required) return -2;

    int[MAX_NODES] keys;
    int[MAX_NODES] left;
    int[MAX_NODES] right;
    for (usz index = 0; index < MAX_NODES; index++) {
        left[index] = -1;
        right[index] = -1;
    }
    usz next_node = 0;
    int root = -1;
    for (usz index = 0; index < count; index++)
        root = insert_node(root, (int)input[index + 1], &keys[0], &left[0], &right[0], &next_node);
    usz position = 0;
    emit_inorder(root, &keys[0], &left[0], &right[0], output, &position);
    return (long)position;
}
