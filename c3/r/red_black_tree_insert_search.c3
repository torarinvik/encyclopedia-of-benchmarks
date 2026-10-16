module red_black_tree_insert_search;

const usz MAX_OPERATIONS = 128;

struct Node { long key; int left; int right; bool red; }

fn bool is_red(Node* tree, int node) { return node != 0 && tree[node].red; }
fn void flip_colors(Node* tree, int node) {
    tree[node].red = !tree[node].red;
    tree[tree[node].left].red = !tree[tree[node].left].red;
    tree[tree[node].right].red = !tree[tree[node].right].red;
}
fn int rotate_left(Node* tree, int node) {
    int pivot = tree[node].right;
    tree[node].right = tree[pivot].left;
    tree[pivot].left = node;
    tree[pivot].red = tree[node].red;
    tree[node].red = true;
    return pivot;
}
fn int rotate_right(Node* tree, int node) {
    int pivot = tree[node].left;
    tree[node].left = tree[pivot].right;
    tree[pivot].right = node;
    tree[pivot].red = tree[node].red;
    tree[node].red = true;
    return pivot;
}
fn int insert_node(Node* tree, int node, long key, int* next) {
    if (node == 0) { int created = *next; *next += 1; tree[created].key = key; tree[created].red = true; return created; }
    if (is_red(tree, tree[node].left) && is_red(tree, tree[node].right)) flip_colors(tree, node);
    if (key == tree[node].key) tree[node].key = key;
    else if (key < tree[node].key) tree[node].left = insert_node(tree, tree[node].left, key, next);
    else tree[node].right = insert_node(tree, tree[node].right, key, next);
    if (is_red(tree, tree[node].right) && !is_red(tree, tree[node].left)) node = rotate_left(tree, node);
    if (is_red(tree, tree[node].left) && is_red(tree, tree[tree[node].left].left)) node = rotate_right(tree, node);
    return node;
}
fn int find_node(Node* tree, int start, long key) {
    int node = start;
    while (node != 0) {
        if (key < tree[node].key) node = tree[node].left;
        else if (key > tree[node].key) node = tree[node].right;
        else return node;
    }
    return 0;
}
fn void insertion_sort(long* values, usz count) {
    for (usz index = 1; index < count; index++) {
        long value = values[index]; usz position = index;
        while (position > 0 && values[position - 1] > value) { values[position] = values[position - 1]; position -= 1; }
        values[position] = value;
    }
}
fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long red_black_tree_insert_search(long* input, usz length, char* output, usz capacity)
    @export("red_black_tree_insert_search") {
    if (input == null || length < 1) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)count_value;
    if (length != 1 + 2 * operation_count) return -1;
    for (usz op = 0; op < operation_count; op++) {
        long opcode = input[1 + 2 * op], key = input[2 + 2 * op];
        if ((opcode != 0 && opcode != 1) || key < -2147483648 || key > 2147483647) return -1;
    }
    Node[MAX_OPERATIONS + 1] tree;
    for (usz index = 0; index <= MAX_OPERATIONS; index++) { tree[index].key = 0; tree[index].left = 0; tree[index].right = 0; tree[index].red = false; }
    long[MAX_OPERATIONS] keys, search_results;
    int root = 0, next = 1;
    usz key_count = 0, search_count = 0;
    for (usz op = 0; op < operation_count; op++) {
        long opcode = input[1 + 2 * op], key = input[2 + 2 * op];
        if (opcode == 0) {
            if (find_node(&tree[0], root, key) != 0) return -1;
            root = insert_node(&tree[0], root, key, &next);
            tree[root].red = false;
            keys[key_count] = key; key_count += 1;
        } else {
            search_results[search_count] = find_node(&tree[0], root, key) != 0 ? 1 : 0;
            search_count += 1;
        }
    }
    insertion_sort(&keys[0], key_count);
    usz required = (2 + key_count + search_count) * 8;
    if (output == null || capacity < required) return -2;
    usz offset = 0;
    write_i64(output, offset, (long)key_count); offset += 8;
    for (usz index = 0; index < key_count; index++) { write_i64(output, offset, keys[index]); offset += 8; }
    write_i64(output, offset, (long)search_count); offset += 8;
    for (usz index = 0; index < search_count; index++) { write_i64(output, offset, search_results[index]); offset += 8; }
    return (long)required;
}
