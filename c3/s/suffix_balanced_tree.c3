module suffix_balanced_tree;

const usz MAX_TEXT = 32;
const usz MAX_INPUT = 33;
const ulong TAG_LIMIT = (ulong)1 << 62;

struct Tree {
    long[MAX_TEXT] text;
    int[MAX_TEXT] left;
    int[MAX_TEXT] right;
    int[MAX_TEXT] size;
    ulong[MAX_TEXT] tag;
    int[MAX_TEXT] buffer;
    long[MAX_TEXT] answer;
    int buffered;
}

fn int node_size(Tree* tree, int node) { return node < 0 ? 0 : tree.size[node]; }
fn bool suffix_less(Tree* tree, int x, int y, int n) {
    if (tree.text[x] != tree.text[y]) return tree.text[x] < tree.text[y];
    ulong next_x = x + 1 < n ? tree.tag[x + 1] : 0;
    ulong next_y = y + 1 < n ? tree.tag[y + 1] : 0;
    return next_x < next_y;
}
fn void flatten(Tree* tree, int root) {
    if (root < 0) return;
    flatten(tree, tree.left[root]);
    tree.buffer[tree.buffered++] = root;
    flatten(tree, tree.right[root]);
}
fn int build_balanced(Tree* tree, int lo, int hi, ulong low, ulong high) {
    if (lo >= hi) return -1;
    int mid = lo + (hi - lo) / 2;
    int root = tree.buffer[mid];
    ulong tag = low + (high - low) / 2;
    tree.tag[root] = tag;
    tree.left[root] = build_balanced(tree, lo, mid, low, tag);
    tree.right[root] = build_balanced(tree, mid + 1, hi, tag, high);
    tree.size[root] = 1 + node_size(tree, tree.left[root]) + node_size(tree, tree.right[root]);
    return root;
}
fn int rebuild(Tree* tree, int root, ulong low, ulong high) {
    tree.buffered = 0;
    flatten(tree, root);
    return build_balanced(tree, 0, tree.buffered, low, high);
}
fn int insert_suffix(Tree* tree, int root, int pos, int n, ulong low, ulong high) {
    if (root < 0) {
        tree.left[pos] = -1; tree.right[pos] = -1; tree.size[pos] = 1;
        tree.tag[pos] = low + (high - low) / 2;
        return pos;
    }
    ulong middle = tree.tag[root];
    if (suffix_less(tree, pos, root, n)) tree.left[root] = insert_suffix(tree, tree.left[root], pos, n, low, middle);
    else tree.right[root] = insert_suffix(tree, tree.right[root], pos, n, middle, high);
    int left_size = node_size(tree, tree.left[root]);
    int right_size = node_size(tree, tree.right[root]);
    tree.size[root] = 1 + left_size + right_size;
    int heavy = left_size > right_size ? left_size : right_size;
    if (4 * heavy >= 3 * tree.size[root]) return rebuild(tree, root, low, high);
    return root;
}
fn void inorder(Tree* tree, int root, usz* count) {
    if (root < 0) return;
    inorder(tree, tree.left[root], count);
    tree.answer[*count] = root; *count = *count + 1;
    inorder(tree, tree.right[root], count);
}
fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255); bits >>= 8; }
}

fn long suffix_balanced_tree(long* input, usz length, uint8* output, usz capacity)
    @export("suffix_balanced_tree") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    long nv = input[0];
    if (nv < 0 || nv > (long)MAX_TEXT || length != 1 + (usz)nv) return -1;
    int n = (int)nv;
    for (int i = 0; i < n; i++) if (input[1 + i] < 0 || input[1 + i] > 255) return -1;
    usz required = 8 * (usz)n;
    if (output == null || capacity < required) return -2;
    Tree tree = {0};
    for (int i = 0; i < n; i++) tree.text[i] = input[1 + i];
    int root = -1;
    for (int pos = n - 1; pos >= 0; pos--) root = insert_suffix(&tree, root, pos, n, 0, TAG_LIMIT);
    usz answer_count = 0;
    inorder(&tree, root, &answer_count);
    for (usz i = 0; i < answer_count; i++) store_le(output, 8 * i, tree.answer[i]);
    return (long)required;
}
