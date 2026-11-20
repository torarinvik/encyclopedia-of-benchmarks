#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT_LENGTH = 32, MAX_INPUT_LENGTH = 34, MAX_NODES = 64 };

struct TrieNode {
    int32_t is_leaf;
    int32_t split_pos;
    int32_t leaf_start;
    int32_t edge_symbol;
    int32_t first_child;
    int32_t next_sibling;
};

struct BlindTrie {
    TrieNode node[MAX_NODES];
    int32_t count;
    int32_t root;
};

static int32_t symbol_at(const int64_t *input, int32_t n,
                         int32_t start, int32_t depth)
{
    const int32_t position = start + depth;
    return position >= n ? 0 : (int32_t)input[position + 1] + 1;
}

static int32_t common_prefix(const int64_t *input, int32_t n,
                             int32_t left, int32_t right)
{
    int32_t depth = 0;
    while (symbol_at(input, n, left, depth) == symbol_at(input, n, right, depth))
        ++depth;
    return depth;
}

static int32_t new_node(BlindTrie *trie, int32_t is_leaf, int32_t value)
{
    const int32_t index = trie->count++;
    trie->node[index].is_leaf = is_leaf;
    trie->node[index].split_pos = is_leaf ? 0 : value;
    trie->node[index].leaf_start = is_leaf ? value : -1;
    trie->node[index].first_child = -1;
    trie->node[index].next_sibling = -1;
    return index;
}

static int32_t find_child(const BlindTrie *trie, int32_t parent, int32_t symbol)
{
    int32_t child = trie->node[parent].first_child;
    while (child >= 0) {
        if (trie->node[child].edge_symbol == symbol) return child;
        if (trie->node[child].edge_symbol > symbol) return -1;
        child = trie->node[child].next_sibling;
    }
    return -1;
}

static void link_child(BlindTrie *trie, int32_t parent, int32_t child)
{
    int32_t previous = -1;
    int32_t cursor = trie->node[parent].first_child;
    const int32_t symbol = trie->node[child].edge_symbol;
    while (cursor >= 0 && trie->node[cursor].edge_symbol < symbol) {
        previous = cursor;
        cursor = trie->node[cursor].next_sibling;
    }
    trie->node[child].next_sibling = cursor;
    if (previous < 0) trie->node[parent].first_child = child;
    else trie->node[previous].next_sibling = child;
}

static void replace_child(BlindTrie *trie, int32_t parent,
                          int32_t old_child, int32_t new_child)
{
    int32_t previous = -1;
    int32_t cursor = trie->node[parent].first_child;
    while (cursor != old_child) {
        previous = cursor;
        cursor = trie->node[cursor].next_sibling;
    }
    trie->node[new_child].edge_symbol = trie->node[old_child].edge_symbol;
    trie->node[new_child].next_sibling = trie->node[old_child].next_sibling;
    if (previous < 0) trie->node[parent].first_child = new_child;
    else trie->node[previous].next_sibling = new_child;
}

static void insert_suffix(BlindTrie *trie, const int64_t *input,
                          int32_t n, int32_t start)
{
    const int32_t fresh = new_node(trie, 1, start);
    if (trie->node[trie->root].is_leaf) {
        const int32_t old = trie->root;
        const int32_t depth = common_prefix(input, n,
                                             trie->node[old].leaf_start, start);
        const int32_t middle = new_node(trie, 0, depth);
        trie->node[old].edge_symbol = symbol_at(input, n, trie->node[old].leaf_start, depth);
        trie->node[fresh].edge_symbol = symbol_at(input, n, start, depth);
        link_child(trie, middle, old);
        link_child(trie, middle, fresh);
        trie->root = middle;
        return;
    }

    int32_t leaf = trie->root;
    while (!trie->node[leaf].is_leaf) {
        const int32_t symbol = symbol_at(input, n, start,
                                         trie->node[leaf].split_pos);
        int32_t child = find_child(trie, leaf, symbol);
        if (child < 0) child = trie->node[leaf].first_child;
        leaf = child;
    }
    const int32_t old_start = trie->node[leaf].leaf_start;
    const int32_t depth = common_prefix(input, n, start, old_start);
    int32_t parent = -1;
    int32_t current = trie->root;
    while (!trie->node[current].is_leaf && trie->node[current].split_pos < depth) {
        const int32_t symbol = symbol_at(input, n, start,
                                         trie->node[current].split_pos);
        int32_t child = find_child(trie, current, symbol);
        if (child < 0) child = trie->node[current].first_child;
        parent = current;
        current = child;
    }
    if (!trie->node[current].is_leaf && trie->node[current].split_pos == depth) {
        trie->node[fresh].edge_symbol = symbol_at(input, n, start, depth);
        link_child(trie, current, fresh);
        return;
    }

    const int32_t middle = new_node(trie, 0, depth);
    if (parent < 0) trie->root = middle;
    else replace_child(trie, parent, current, middle);
    trie->node[current].edge_symbol = symbol_at(input, n, old_start, depth);
    trie->node[fresh].edge_symbol = symbol_at(input, n, start, depth);
    link_child(trie, middle, current);
    link_child(trie, middle, fresh);
}

static int32_t ordered_leaves(const BlindTrie *trie,
                              int32_t output[MAX_TEXT_LENGTH])
{
    int32_t stack[MAX_NODES];
    int32_t top = 0;
    int32_t count = 0;
    stack[top++] = trie->root;
    while (top > 0) {
        const int32_t node = stack[--top];
        if (trie->node[node].is_leaf) {
            output[count++] = trie->node[node].leaf_start;
            continue;
        }
        int32_t children[MAX_TEXT_LENGTH];
        int32_t child_count = 0;
        int32_t child = trie->node[node].first_child;
        while (child >= 0) {
            children[child_count++] = child;
            child = trie->node[child].next_sibling;
        }
        while (child_count > 0) stack[top++] = children[--child_count];
    }
    return count;
}

extern "C" int64_t suffix_array_blind_trie(const int64_t *values, size_t length,
                                            uint8_t *output, size_t capacity)
{
    if (values == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    const int32_t count = static_cast<int32_t>(count_value);
    if (length != static_cast<size_t>(count) + 1) return -1;
    for (int32_t i = 0; i < count; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 255) return -1;
    const size_t output_bytes = static_cast<size_t>(count) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    if (count == 0) return 0;

    BlindTrie trie{};
    for (int32_t i = 0; i < MAX_NODES; ++i) {
        trie.node[i].first_child = -1;
        trie.node[i].next_sibling = -1;
    }
    trie.root = new_node(&trie, 1, 0);
    for (int32_t start = 1; start < count; ++start)
        insert_suffix(&trie, values, count, start);
    int32_t order[MAX_TEXT_LENGTH];
    const int32_t ordered_count = ordered_leaves(&trie, order);
    for (int32_t i = 0; i < ordered_count; ++i) {
        const uint64_t bits = static_cast<uint64_t>(order[i]);
        for (size_t byte = 0; byte < 8; ++byte)
            output[static_cast<size_t>(i) * 8 + byte] = static_cast<uint8_t>(bits >> (byte * 8));
    }
    return static_cast<int64_t>(output_bytes);
}
