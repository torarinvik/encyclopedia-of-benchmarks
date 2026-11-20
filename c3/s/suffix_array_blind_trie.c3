module suffix_array_blind_trie;

const int MAX_TEXT_LENGTH = 32;
const usz MAX_INPUT_LENGTH = 34;
const int MAX_NODES = 64;

struct TrieNode {
    int is_leaf;
    int split_pos;
    int leaf_start;
    int edge_symbol;
    int first_child;
    int next_sibling;
}
struct BlindTrie { TrieNode[MAX_NODES] node; int count; int root; }

fn int symbol_at(long* input, int n, int start, int depth) {
    int position = start + depth;
    if (position >= n) return 0;
    return (int)input[position + 1] + 1;
}

fn int common_prefix(long* input, int n, int left, int right) {
    int depth = 0;
    while (symbol_at(input, n, left, depth) == symbol_at(input, n, right, depth)) depth++;
    return depth;
}

fn int new_node(BlindTrie* trie, int is_leaf, int value) {
    int index = trie.count++;
    trie.node[index].is_leaf = is_leaf;
    trie.node[index].split_pos = is_leaf != 0 ? 0 : value;
    trie.node[index].leaf_start = is_leaf != 0 ? value : -1;
    trie.node[index].first_child = -1;
    trie.node[index].next_sibling = -1;
    return index;
}

fn int find_child(BlindTrie* trie, int parent, int symbol) {
    int child = trie.node[parent].first_child;
    while (child >= 0) {
        if (trie.node[child].edge_symbol == symbol) return child;
        if (trie.node[child].edge_symbol > symbol) return -1;
        child = trie.node[child].next_sibling;
    }
    return -1;
}

fn void link_child(BlindTrie* trie, int parent, int child) {
    int previous = -1;
    int cursor = trie.node[parent].first_child;
    int symbol = trie.node[child].edge_symbol;
    while (cursor >= 0 && trie.node[cursor].edge_symbol < symbol) {
        previous = cursor;
        cursor = trie.node[cursor].next_sibling;
    }
    trie.node[child].next_sibling = cursor;
    if (previous < 0) trie.node[parent].first_child = child;
    else trie.node[previous].next_sibling = child;
}

fn void replace_child(BlindTrie* trie, int parent, int old_child, int new_child) {
    int previous = -1;
    int cursor = trie.node[parent].first_child;
    while (cursor != old_child) {
        previous = cursor;
        cursor = trie.node[cursor].next_sibling;
    }
    trie.node[new_child].edge_symbol = trie.node[old_child].edge_symbol;
    trie.node[new_child].next_sibling = trie.node[old_child].next_sibling;
    if (previous < 0) trie.node[parent].first_child = new_child;
    else trie.node[previous].next_sibling = new_child;
}

fn void insert_suffix(BlindTrie* trie, long* input, int n, int start) {
    int fresh = new_node(trie, 1, start);
    if (trie.node[trie.root].is_leaf != 0) {
        int old = trie.root;
        int depth = common_prefix(input, n, trie.node[old].leaf_start, start);
        int middle = new_node(trie, 0, depth);
        trie.node[old].edge_symbol = symbol_at(input, n, trie.node[old].leaf_start, depth);
        trie.node[fresh].edge_symbol = symbol_at(input, n, start, depth);
        link_child(trie, middle, old);
        link_child(trie, middle, fresh);
        trie.root = middle;
        return;
    }

    int leaf = trie.root;
    while (trie.node[leaf].is_leaf == 0) {
        int symbol = symbol_at(input, n, start, trie.node[leaf].split_pos);
        int child = find_child(trie, leaf, symbol);
        if (child < 0) child = trie.node[leaf].first_child;
        leaf = child;
    }
    int old_start = trie.node[leaf].leaf_start;
    int depth = common_prefix(input, n, start, old_start);
    int parent = -1;
    int current = trie.root;
    while (trie.node[current].is_leaf == 0 && trie.node[current].split_pos < depth) {
        int symbol = symbol_at(input, n, start, trie.node[current].split_pos);
        int child = find_child(trie, current, symbol);
        if (child < 0) child = trie.node[current].first_child;
        parent = current;
        current = child;
    }
    if (trie.node[current].is_leaf == 0 && trie.node[current].split_pos == depth) {
        trie.node[fresh].edge_symbol = symbol_at(input, n, start, depth);
        link_child(trie, current, fresh);
        return;
    }
    int middle = new_node(trie, 0, depth);
    if (parent < 0) trie.root = middle;
    else replace_child(trie, parent, current, middle);
    trie.node[current].edge_symbol = symbol_at(input, n, old_start, depth);
    trie.node[fresh].edge_symbol = symbol_at(input, n, start, depth);
    link_child(trie, middle, current);
    link_child(trie, middle, fresh);
}

fn int ordered_leaves(BlindTrie* trie, int* output) {
    int[MAX_NODES] stack;
    int top = 0;
    int count = 0;
    stack[top++] = trie.root;
    while (top > 0) {
        int node = stack[--top];
        if (trie.node[node].is_leaf != 0) {
            output[count++] = trie.node[node].leaf_start;
            continue;
        }
        int[MAX_TEXT_LENGTH] children;
        int child_count = 0;
        int child = trie.node[node].first_child;
        while (child >= 0) {
            children[child_count++] = child;
            child = trie.node[child].next_sibling;
        }
        while (child_count > 0) stack[top++] = children[--child_count];
    }
    return count;
}

fn long suffix_array_blind_trie(long* values, usz length, char* output, usz capacity)
        @export("suffix_array_blind_trie") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    int count = (int)count_value;
    if (length != (usz)count + 1) return -1;
    for (int i = 0; i < count; i++) if (values[i + 1] < 0 || values[i + 1] > 255) return -1;
    usz output_bytes = (usz)count * 8;
    if (output == null || capacity < output_bytes) return -2;
    if (count == 0) return 0;

    BlindTrie trie = zeroed;
    for (int i = 0; i < MAX_NODES; i++) {
        trie.node[i].first_child = -1;
        trie.node[i].next_sibling = -1;
    }
    trie.root = new_node(&trie, 1, 0);
    for (int start = 1; start < count; start++) insert_suffix(&trie, values, count, start);
    int[MAX_TEXT_LENGTH] order;
    int ordered_count = ordered_leaves(&trie, &order[0]);
    for (int i = 0; i < ordered_count; i++) {
        ulong bits = (ulong)order[i];
        for (usz byte = 0; byte < 8; byte++) output[(usz)i * 8 + byte] = (char)(bits >> (byte * 8));
    }
    return (long)output_bytes;
}
