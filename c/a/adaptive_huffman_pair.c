#include <stddef.h>
#include <stdint.h>

enum { ALPHABET = 16, MAX_NODES = 31, MAX_SYMBOLS = 64, MAX_BITS = 1216,
       MAX_PACKED = 152, MAX_OUTPUT = 160, MAX_INPUT = 66 };
enum { NYT = 0, LEAF = 1, INTERNAL = 2 };

typedef struct {
    int parent, left, right, symbol, kind;
    int64_t weight;
} AhNode;

typedef struct {
    uint8_t bytes[MAX_PACKED];
    size_t bit_count;
} AhBits;

typedef struct {
    AhNode nodes[MAX_NODES];
    int node_count, root, nyt;
    int leaf_of[ALPHABET];
    int fgk_order[MAX_NODES];
    int order_count;
    AhBits bits;
} AhTree;

static void put_bit(AhBits *bits, unsigned value) {
    if (value != 0) bits->bytes[bits->bit_count / 8] |= (uint8_t)(1u << (7u - (unsigned)(bits->bit_count % 8)));
    ++bits->bit_count;
}

static void put_value(AhBits *bits, unsigned value, unsigned width) {
    for (unsigned shift = width; shift > 0; --shift) put_bit(bits, (value >> (shift - 1)) & 1u);
}

static void encode_path(AhTree *tree, int node) {
    unsigned reverse_path[MAX_NODES];
    size_t depth = 0;
    while (node != tree->root) {
        int parent = tree->nodes[node].parent;
        reverse_path[depth++] = tree->nodes[parent].right == node ? 1u : 0u;
        node = parent;
    }
    while (depth > 0) put_bit(&tree->bits, reverse_path[--depth]);
}

static int is_ancestor(const AhTree *tree, int ancestor, int node) {
    for (int at = tree->nodes[node].parent; at >= 0; at = tree->nodes[at].parent)
        if (at == ancestor) return 1;
    return 0;
}

static void replace_child(AhTree *tree, int parent, int old_child, int new_child) {
    if (tree->nodes[parent].left == old_child) tree->nodes[parent].left = new_child;
    else if (tree->nodes[parent].right == old_child) tree->nodes[parent].right = new_child;
}

static void swap_positions(AhTree *tree, int a, int b, int update_fgk_order) {
    if (a == b || tree->nodes[a].parent == b || tree->nodes[b].parent == a) return;
    int pa = tree->nodes[a].parent, pb = tree->nodes[b].parent;
    if (pa == pb) {
        if (pa >= 0) {
            int temp = tree->nodes[pa].left;
            tree->nodes[pa].left = tree->nodes[pa].right;
            tree->nodes[pa].right = temp;
        }
    } else {
        if (pa >= 0) replace_child(tree, pa, a, b);
        if (pb >= 0) replace_child(tree, pb, b, a);
        tree->nodes[a].parent = pb;
        tree->nodes[b].parent = pa;
    }
    if (tree->root == a) tree->root = b;
    else if (tree->root == b) tree->root = a;
    if (update_fgk_order) {
        int ra = -1, rb = -1;
        for (int i = 0; i < tree->order_count; ++i) {
            if (tree->fgk_order[i] == a) ra = i;
            if (tree->fgk_order[i] == b) rb = i;
        }
        if (ra >= 0 && rb >= 0) {
            tree->fgk_order[ra] = b;
            tree->fgk_order[rb] = a;
        }
    }
}

static void initialize(AhTree *tree) {
    *tree = (AhTree){0};
    tree->node_count = 1;
    tree->root = tree->nyt = 0;
    tree->nodes[0] = (AhNode){.parent=-1,.left=-1,.right=-1,.symbol=-1,.kind=NYT,.weight=0};
    tree->fgk_order[0] = 0;
    tree->order_count = 1;
    for (int i = 0; i < ALPHABET; ++i) tree->leaf_of[i] = -1;
}

static int add_node(AhTree *tree, int parent, int kind, int symbol) {
    int id = tree->node_count++;
    tree->nodes[id] = (AhNode){.parent=parent,.left=-1,.right=-1,.symbol=symbol,.kind=kind,.weight=0};
    return id;
}

static int split_nyt(AhTree *tree, int symbol, int has_remaining, int for_fgk) {
    int old = tree->nyt;
    if (!has_remaining) {
        tree->nodes[old].kind = LEAF;
        tree->nodes[old].symbol = symbol;
        tree->leaf_of[symbol] = old;
        tree->nyt = -1;
        return old;
    }
    int left = add_node(tree, old, NYT, -1);
    int right = add_node(tree, old, LEAF, symbol);
    tree->nodes[old].kind = INTERNAL;
    tree->nodes[old].left = left;
    tree->nodes[old].right = right;
    tree->leaf_of[symbol] = right;
    tree->nyt = left;
    if (for_fgk) {
        int position = 0;
        while (tree->fgk_order[position] != old) ++position;
        for (int i = tree->order_count + 1; i > position + 2; --i) tree->fgk_order[i] = tree->fgk_order[i - 2];
        tree->fgk_order[position] = left;
        tree->fgk_order[position + 1] = right;
        tree->fgk_order[position + 2] = old;
        tree->order_count += 2;
    }
    return right;
}

static int highest_fgk_node(const AhTree *tree, int node, int leaves_only) {
    int weight = (int)tree->nodes[node].weight;
    int parent = tree->nodes[node].parent;
    for (int i = tree->order_count - 1; i >= 0; --i) {
        int candidate = tree->fgk_order[i];
        if (candidate == parent || tree->nodes[candidate].weight != weight ||
            (leaves_only && tree->nodes[candidate].kind == INTERNAL) ||
            is_ancestor(tree, candidate, node) || is_ancestor(tree, node, candidate)) continue;
        return candidate;
    }
    return node;
}

static void update_fgk(AhTree *tree, int node) {
    int parent = tree->nodes[node].parent;
    if (tree->nyt >= 0 && parent >= 0 && tree->nodes[tree->nyt].parent == parent) {
        int leader = highest_fgk_node(tree, node, 1);
        swap_positions(tree, node, leader, 1);
        ++tree->nodes[node].weight;
        node = tree->nodes[node].parent;
    }
    while (node != tree->root) {
        int leader = highest_fgk_node(tree, node, 0);
        swap_positions(tree, node, leader, 1);
        ++tree->nodes[node].weight;
        node = tree->nodes[node].parent;
    }
    ++tree->nodes[tree->root].weight;
}

typedef struct { int id, depth, path; } OrderedNode;

static int implicit_order(AhTree *tree, OrderedNode *order) {
    for (int id = 0; id < tree->node_count; ++id) {
        int path_bits[MAX_NODES], depth = 0, at = id, path = 0;
        while (at != tree->root) {
            int p = tree->nodes[at].parent;
            path_bits[depth++] = tree->nodes[p].right == at;
            at = p;
        }
        for (int i = depth - 1; i >= 0; --i) path = path * 2 + path_bits[i];
        order[id] = (OrderedNode){.id=id,.depth=depth,.path=path};
    }
    for (int i = 1; i < tree->node_count; ++i) {
        OrderedNode value = order[i];
        int j = i;
        while (j > 0 && (order[j-1].depth < value.depth ||
               (order[j-1].depth == value.depth && order[j-1].path > value.path))) {
            order[j] = order[j-1];
            --j;
        }
        order[j] = value;
    }
    return tree->node_count;
}

static int highest_vitter_block(AhTree *tree, int node, OrderedNode *order) {
    int count = implicit_order(tree, order);
    for (int i = count - 1; i >= 0; --i) {
        int candidate = order[i].id;
        if (tree->nodes[candidate].weight == tree->nodes[node].weight &&
            tree->nodes[candidate].kind == tree->nodes[node].kind) return candidate;
    }
    return node;
}

static int slide_increment(AhTree *tree, int node, OrderedNode *order) {
    int old_parent = tree->nodes[node].parent;
    int target_kind = tree->nodes[node].kind == LEAF ? INTERNAL : LEAF;
    int target_weight = tree->nodes[node].weight + (tree->nodes[node].kind == LEAF ? 0 : 1);
    OrderedNode ordered[MAX_NODES];
    int count = implicit_order(tree, ordered);
    int block[MAX_NODES], block_count = 0;
    for (int i = 0; i < count; ++i) {
        int candidate = ordered[i].id;
        if (tree->nodes[candidate].kind == target_kind && tree->nodes[candidate].weight == target_weight)
            block[block_count++] = candidate;
    }
    for (int i = 0; i < block_count; ++i)
        if (block[i] != node) swap_positions(tree, node, block[i], 0);
    ++tree->nodes[node].weight;
    return tree->nodes[node].kind == LEAF ? tree->nodes[node].parent : old_parent;
}

static void update_vitter(AhTree *tree, int node, int just_split) {
    OrderedNode order[MAX_NODES];
    int leaf_to_increment = -1;
    if (just_split) {
        leaf_to_increment = node;
        node = tree->nodes[node].parent;
    } else {
        int leader = highest_vitter_block(tree, node, order);
        swap_positions(tree, node, leader, 0);
        if (tree->nyt >= 0 && tree->nodes[node].parent >= 0 &&
            tree->nodes[tree->nyt].parent == tree->nodes[node].parent) {
            leaf_to_increment = node;
            node = tree->nodes[node].parent;
        }
    }
    while (node != tree->root) node = slide_increment(tree, node, order);
    if (leaf_to_increment >= 0) (void)slide_increment(tree, leaf_to_increment, order);
    ++tree->nodes[tree->root].weight;
}

static int run(const int64_t *input, size_t length, uint8_t *output,
               size_t capacity, int use_vitter) {
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_SYMBOLS || length != 1 + (size_t)n_value) return -1;
    for (size_t i = 0; i < (size_t)n_value; ++i)
        if (input[1 + i] < 0 || input[1 + i] >= ALPHABET) return -1;
    AhTree tree;
    initialize(&tree);
    int seen_count = 0;
    for (size_t i = 0; i < (size_t)n_value; ++i) {
        int symbol = (int)input[1 + i];
        int is_new = tree.leaf_of[symbol] < 0;
        int current = is_new ? tree.nyt : tree.leaf_of[symbol];
        int just_split = 0;
        if (current < 0) return -1;
        encode_path(&tree, current);
        if (is_new) put_value(&tree.bits, (unsigned)symbol, 4);
        if (is_new) {
            ++seen_count;
            just_split = seen_count < ALPHABET;
            current = split_nyt(&tree, symbol, just_split, !use_vitter);
        }
        if (use_vitter) update_vitter(&tree, current, just_split);
        else update_fgk(&tree, current);
    }
    size_t packed = (tree.bits.bit_count + 7) / 8;
    size_t required = 8 + packed;
    if (output == NULL || capacity < required) return -2;
    uint64_t count = (uint64_t)tree.bits.bit_count;
    for (size_t i = 0; i < 8; ++i) output[i] = (uint8_t)(count >> (8 * i));
    for (size_t i = 0; i < packed; ++i) output[8 + i] = tree.bits.bytes[i];
    return (int)required;
}

int64_t fgk_adaptive_huffman(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity) {
    return run(input, length, output, capacity, 0);
}

int64_t vitter_adaptive_huffman(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    return run(input, length, output, capacity, 1);
}
