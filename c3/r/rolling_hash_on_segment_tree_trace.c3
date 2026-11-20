module rolling_hash_on_segment_tree_trace;

struct Node { long hash; int length; }

const int MAX_N = 20;
const int MAX_Q = 20;
const int TREE_CAPACITY = 64;
const long HASH_MOD = 1000000007;
const long HASH_BASE = 911382323;
const usz MAX_PARSEABLE_INPUT = 123;

fn long concatenate_hash(long left_hash, long right_hash, int right_length, long* powers) {
    return (left_hash * powers[right_length] + right_hash) % HASH_MOD;
}

fn void pull(Node* tree, int node, long* powers) {
    Node left = tree[2 * node];
    Node right = tree[2 * node + 1];
    tree[node].hash = concatenate_hash(left.hash, right.hash, right.length, powers);
    tree[node].length = left.length + right.length;
}

fn long range_hash(Node* tree, int tree_size, int left, int right, long* powers) {
    long left_hash = 0, right_hash = 0;
    int right_length = 0;
    left += tree_size;
    right += tree_size;
    while (left < right) {
        if ((left & 1) != 0) {
            Node part = tree[left];
            left = left + 1;
            left_hash = concatenate_hash(left_hash, part.hash, part.length, powers);
        }
        if ((right & 1) != 0) {
            right = right - 1;
            Node part = tree[right];
            right_hash = concatenate_hash(part.hash, right_hash, right_length, powers);
            right_length = right_length + part.length;
        }
        left /= 2;
        right /= 2;
    }
    return concatenate_hash(left_hash, right_hash, right_length, powers);
}

fn long rolling_hash_on_segment_tree_trace(long* input, usz length) @export("rolling_hash_on_segment_tree_trace") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q) return -1;
    int n = (int)input[0], q = (int)input[1];
    if (length != (usz)(2 + n + 5 * q)) return -1;

    long[MAX_N + 1] powers;
    powers[0] = 1;
    for (int i = 1; i <= MAX_N; i++) powers[i] = (powers[i - 1] * HASH_BASE) % HASH_MOD;

    int tree_size = 1;
    while (tree_size < n) tree_size = tree_size * 2;
    Node[TREE_CAPACITY] tree = zeroed;
    for (int i = 0; i < n; i++) {
        long symbol = input[2 + (usz)i];
        if (symbol < 0 || symbol > 25) return -1;
        tree[tree_size + i].hash = symbol;
        tree[tree_size + i].length = 1;
    }
    for (int node = tree_size - 1; node > 0; node--) pull(&tree[0], node, &powers[0]);

    long checksum = 0;
    for (int operation = 0; operation < q; operation++) {
        usz at = 2 + (usz)n + 5 * (usz)operation;
        long opcode = input[at];
        long a = input[at + 1], b = input[at + 2];
        long c = input[at + 3], d = input[at + 4];
        int response = 0;

        if (opcode == 0) {
            if (a < 0 || a >= n || b < 0 || b > 25 || c != 0 || d != 0) return -1;
            int node = tree_size + (int)a;
            tree[node].hash = b;
            tree[node].length = 1;
            while (node > 1) {
                node /= 2;
                pull(&tree[0], node, &powers[0]);
            }
        } else if (opcode == 1) {
            if (a < 0 || a > b || b > n || c < 0 || c > d || d > n) return -1;
            if (b - a == d - c && range_hash(&tree[0], tree_size, (int)a, (int)b, &powers[0]) ==
                                   range_hash(&tree[0], tree_size, (int)c, (int)d, &powers[0])) response = 1;
        } else {
            return -1;
        }
        checksum = checksum + (long)(operation + 1) * (opcode * 2 + response + 1);
    }
    return checksum;
}
