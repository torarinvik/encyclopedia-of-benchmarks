module splay_tree;

const usz MAX_OPS = 64;
const usz MAX_KEYS = 32;
const usz MAX_INPUT = 130;
const usz MAX_OUTPUT = 784;

struct Node { int key; int left; int right; }

fn int rotate_right(Node* nodes, int root) {
    int child = nodes[root].left;
    nodes[root].left = nodes[child].right;
    nodes[child].right = root;
    return child;
}
fn int rotate_left(Node* nodes, int root) {
    int child = nodes[root].right;
    nodes[root].right = nodes[child].left;
    nodes[child].left = root;
    return child;
}
fn int splay(Node* nodes, int root, int key) {
    if (root < 0 || nodes[root].key == key) return root;
    if (key < nodes[root].key) {
        int left = nodes[root].left;
        if (left < 0) return root;
        if (key < nodes[left].key) {
            nodes[left].left = splay(nodes, nodes[left].left, key);
            root = rotate_right(nodes, root);
        } else if (key > nodes[left].key) {
            nodes[left].right = splay(nodes, nodes[left].right, key);
            if (nodes[left].right >= 0) nodes[root].left = rotate_left(nodes, left);
        }
        return nodes[root].left < 0 ? root : rotate_right(nodes, root);
    }
    int right = nodes[root].right;
    if (right < 0) return root;
    if (key > nodes[right].key) {
        nodes[right].right = splay(nodes, nodes[right].right, key);
        root = rotate_left(nodes, root);
    } else if (key < nodes[right].key) {
        nodes[right].left = splay(nodes, nodes[right].left, key);
        if (nodes[right].left >= 0) nodes[root].right = rotate_right(nodes, right);
    }
    return nodes[root].right < 0 ? root : rotate_left(nodes, root);
}
fn void inorder(Node* nodes, int root, long* keys, usz* count) {
    if (root < 0) return;
    inorder(nodes, nodes[root].left, keys, count);
    keys[(*count)++] = (long)nodes[root].key;
    inorder(nodes, nodes[root].right, keys, count);
}
fn void write_word(uint8* output, usz* offset, long word) {
    ulong bits = (ulong)word;
    for (usz shift = 0; shift < 64; shift += 8) output[(*offset)++] = (uint8)(bits >> shift);
}

fn long splay_tree(long* input, usz input_length, char* output, usz capacity)
    @export("splay_tree") {
    if (input == null || input_length == 0 || input_length > MAX_INPUT || input[0] < 0 || input[0] > 64) return -1L;
    usz op_count = (usz)input[0];
    if (input_length != 1 + 2 * op_count) return -1L;
    long[MAX_OPS] ops = zeroed, keys = zeroed, tags = zeroed;
    long[MAX_KEYS] live = zeroed;
    usz live_count = 0, offset = 1;
    for (usz i = 0; i < op_count; i++) {
        long op = input[offset++], key = input[offset++];
        if ((op != 0 && op != 1 && op != 2) || key < -2147483648L || key > 2147483647L) return -1L;
        ops[i] = op; keys[i] = key;
        usz found = live_count;
        for (usz j = 0; j < live_count; j++) if (live[j] == key) { found = j; break; }
        if (op == 0) {
            if (found < live_count || live_count == MAX_KEYS) return -1L;
            live[live_count++] = key;
        } else if (op == 2) {
            if (live_count == 0) return -1L;
            if (found < live_count) live[found] = live[--live_count];
        }
    }
    Node[MAX_OPS] nodes = zeroed;
    usz node_count = 0;
    int root = -1;
    for (usz i = 0; i < op_count; i++) {
        int key = (int)keys[i];
        if (ops[i] == 0) {
            if (root < 0) { nodes[node_count] = {key, -1, -1}; root = (int)node_count++; }
            else {
                root = splay(&nodes[0], root, key);
                nodes[node_count] = {key, -1, -1};
                int fresh = (int)node_count++;
                if (key < nodes[root].key) { nodes[fresh].left = nodes[root].left; nodes[fresh].right = root; nodes[root].left = -1; }
                else { nodes[fresh].right = nodes[root].right; nodes[fresh].left = root; nodes[root].right = -1; }
                root = fresh;
            }
            tags[i] = -2;
        } else if (ops[i] == 1) {
            root = splay(&nodes[0], root, key);
            tags[i] = root >= 0 && nodes[root].key == key ? 1 : 0;
        } else {
            root = splay(&nodes[0], root, key);
            tags[i] = -3;
            if (nodes[root].key == key) {
                int left = nodes[root].left, right = nodes[root].right;
                if (left < 0) root = right;
                else { root = splay(&nodes[0], left, key); nodes[root].right = right; }
            }
        }
    }
    long[MAX_KEYS] final_keys = zeroed;
    usz final_count = 0;
    inorder(&nodes[0], root, &final_keys[0], &final_count);
    uint8[MAX_OUTPUT] staged = zeroed;
    usz written = 0;
    write_word(&staged[0], &written, (long)op_count);
    for (usz i = 0; i < op_count; i++) write_word(&staged[0], &written, tags[i]);
    write_word(&staged[0], &written, (long)final_count);
    for (usz i = 0; i < final_count; i++) write_word(&staged[0], &written, final_keys[i]);
    if (output == null || capacity < written) return -2L;
    for (usz i = 0; i < written; i++) output[i] = (char)staged[i];
    return (long)written;
}
