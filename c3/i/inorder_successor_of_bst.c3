module inorder_successor_of_bst;

const usz MAX_NODES = 64;
const usz MAX_INPUT_LENGTH = 67;

fn long inorder_successor_of_bst(long* input, usz length) @export("inorder_successor_of_bst") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0], target = input[1];
    if (count_value < 0 || count_value > (long)MAX_NODES || target < 1 || target > 2147483647 ||
        length != (usz)count_value + 2) return -1;

    usz count = (usz)count_value;
    long[MAX_NODES] keys;
    int[MAX_NODES] left, right;
    int root = -1;
    for (usz index = 0; index < count; index += 1) {
        long key = input[index + 2];
        if (key < 1 || key > 2147483647) return -1;
        for (usz previous = 0; previous < index; previous += 1) {
            if (keys[previous] == key) return -1;
        }
        keys[index] = key;
        left[index] = -1;
        right[index] = -1;
        int node = (int)index;
        if (root < 0) {
            root = node;
            continue;
        }
        int current = root;
        while (true) {
            if (key <= keys[current]) {
                if (left[current] < 0) {
                    left[current] = node;
                    break;
                }
                current = left[current];
            } else {
                if (right[current] < 0) {
                    right[current] = node;
                    break;
                }
                current = right[current];
            }
        }
    }

    int current = root;
    while (current >= 0 && keys[current] != target) {
        current = target > keys[current] ? right[current] : left[current];
    }
    if (current < 0) return 0;
    if (right[current] >= 0) {
        int successor = right[current];
        while (left[successor] >= 0) successor = left[successor];
        return keys[successor];
    }
    int successor = -1, ancestor = root;
    while (ancestor >= 0 && ancestor != current) {
        if (keys[current] < keys[ancestor]) {
            successor = ancestor;
            ancestor = left[ancestor];
        } else {
            ancestor = right[ancestor];
        }
    }
    return successor < 0 ? 0 : keys[successor];
}
