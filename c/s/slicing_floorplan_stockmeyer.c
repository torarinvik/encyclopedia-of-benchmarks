#include <stddef.h>
#include <stdint.h>

#define MAX_LEAVES 8
#define MAX_NODES 15
#define MAX_CANDIDATES 256
#define MAX_INPUT 32
#define OUTPUT_BYTES 32

typedef struct { int64_t height, width; uint64_t mask; } Candidate;
typedef struct {
    int op, left, right;
    int64_t cell_height, cell_width;
    size_t leaf_index, count;
    Candidate candidates[MAX_CANDIDATES];
} Node;

static int mask_lex_less(uint64_t a, uint64_t b, size_t leaves)
{
    for (size_t bit = 0; bit < leaves; ++bit) {
        const int av = (int)((a >> bit) & 1U), bv = (int)((b >> bit) & 1U);
        if (av != bv) return av < bv;
    }
    return 0;
}

static void prune(Node *node, size_t leaves)
{
    uint8_t dominated[MAX_CANDIDATES] = {0};
    for (size_t i = 0; i < node->count; ++i) {
        const Candidate a = node->candidates[i];
        for (size_t j = 0; j < node->count; ++j) {
            if (i == j) continue;
            const Candidate b = node->candidates[j];
            if (b.height <= a.height && b.width <= a.width) {
                if (b.height < a.height || b.width < a.width
                    || mask_lex_less(b.mask, a.mask, leaves)
                    || (b.mask == a.mask && j < i)) {
                    dominated[i] = 1;
                    break;
                }
            }
        }
    }
    size_t kept = 0;
    for (size_t i = 0; i < node->count; ++i)
        if (!dominated[i]) node->candidates[kept++] = node->candidates[i];
    node->count = kept;
}

static void store_i64_le(uint8_t *output, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t slicing_floorplan_stockmeyer(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_LEAVES) return -1;
    const size_t leaves = (size_t)input[0];
    Node nodes[MAX_NODES] = {0};
    int stack[MAX_NODES];
    size_t stack_size = 0, node_count = 0, leaf_count = 0, internal_count = 0;
    size_t position = 1;
    while (position < length) {
        const int64_t token = input[position++];
        if (token == 2) {
            if (position + 2 > length || leaf_count >= leaves || node_count >= MAX_NODES) return -1;
            const int64_t height = input[position++], width = input[position++];
            if (height < 1 || height > 20 || width < 1 || width > 20) return -1;
            Node *node = &nodes[node_count];
            node->op = 2; node->left = -1; node->right = -1;
            node->cell_height = height; node->cell_width = width;
            node->leaf_index = leaf_count++;
            node->candidates[0] = (Candidate){height, width, 0};
            node->candidates[1] = (Candidate){width, height, UINT64_C(1) << node->leaf_index};
            node->count = 2;
            prune(node, leaves);
            stack[stack_size++] = (int)node_count++;
        } else if (token == 0 || token == 1) {
            if (stack_size < 2 || internal_count >= leaves - 1 || node_count >= MAX_NODES) return -1;
            const int right = stack[--stack_size], left = stack[--stack_size];
            if (nodes[right].op == (int)token) return -1;
            Node *node = &nodes[node_count];
            node->op = (int)token; node->left = left; node->right = right;
            for (size_t i = 0; i < nodes[left].count; ++i) {
                for (size_t j = 0; j < nodes[right].count; ++j) {
                    if (node->count >= MAX_CANDIDATES) return -1;
                    const Candidate a = nodes[left].candidates[i], b = nodes[right].candidates[j];
                    Candidate c;
                    c.mask = a.mask | b.mask;
                    if (token == 0) {
                        c.height = a.height > b.height ? a.height : b.height;
                        c.width = a.width + b.width;
                    } else {
                        c.height = a.height + b.height;
                        c.width = a.width > b.width ? a.width : b.width;
                    }
                    node->candidates[node->count++] = c;
                }
            }
            prune(node, leaves);
            stack[stack_size++] = (int)node_count++;
            ++internal_count;
        } else {
            return -1;
        }
    }
    if (position != length || leaf_count != leaves || internal_count != leaves - 1
        || node_count != 2 * leaves - 1 || stack_size != 1) return -1;

    const Node *root = &nodes[stack[0]];
    if (root->count == 0) return -1;
    Candidate best = root->candidates[0];
    for (size_t i = 1; i < root->count; ++i) {
        const Candidate candidate = root->candidates[i];
        const int64_t area = candidate.height * candidate.width;
        const int64_t best_area = best.height * best.width;
        if (area < best_area || (area == best_area && (candidate.height < best.height
            || (candidate.height == best.height && (candidate.width < best.width
            || (candidate.width == best.width && mask_lex_less(candidate.mask, best.mask, leaves)))))))
            best = candidate;
    }
    if (output == NULL || capacity < OUTPUT_BYTES) return -2;
    uint8_t staged[OUTPUT_BYTES];
    store_i64_le(staged, best.height * best.width);
    store_i64_le(staged + 8, best.height);
    store_i64_le(staged + 16, best.width);
    store_i64_le(staged + 24, (int64_t)best.mask);
    for (size_t byte = 0; byte < OUTPUT_BYTES; ++byte) output[byte] = staged[byte];
    return OUTPUT_BYTES;
}
