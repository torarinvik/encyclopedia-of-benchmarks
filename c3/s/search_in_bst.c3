module search_in_bst;

const usz MAX_NODE_COUNT = 5000;
const long MAX_VALUE = 10000000;

fn long search_in_bst(long* input, usz length) @export("search_in_bst") {
    if (input == null || length < 3) return -1;
    long count_value = input[0];
    long root = input[1];
    long target = input[2];
    if (count_value < 0 || (usz)count_value > MAX_NODE_COUNT ||
        length != 3 + 3 * (usz)count_value || target < 1 || target > MAX_VALUE) return -1;
    usz count = (usz)count_value;
    if (count == 0) return -1;
    if (root < 0 || (usz)root >= count) return -1;
    long node = root;
    while (node != -1) {
        if (node < 0 || (usz)node >= count) return -1;
        usz offset = 3 + 3 * (usz)node;
        long value = input[offset];
        long left = input[offset + 1];
        long right = input[offset + 2];
        if (value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
            (left >= 0 && (usz)left >= count) || (right >= 0 && (usz)right >= count)) return -1;
        if (value == target) return node;
        node = target < value ? left : right;
    }
    return -1;
}
