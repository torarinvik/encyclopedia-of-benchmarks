#include <stddef.h>
#include <stdint.h>

#define MIN_RUNS INT64_C(1)
#define MAX_RUNS INT64_C(100)
#define ELEMENT_COUNT 5000
#define MAX_OUTPUT_BYTES 700
#define NO_CHILD (-1)

typedef struct { int32_t value; int32_t left; int32_t right; } TreeNode;

static int32_t next_random(int64_t *seed) {
    *seed = (*seed * INT64_C(1309) + INT64_C(13849)) & INT64_C(65535);
    return (int32_t)*seed;
}

static int validate_tree(const TreeNode *nodes, int32_t root) {
    const TreeNode *node = &nodes[root];
    if (node->left != NO_CHILD) {
        if (nodes[node->left].value <= node->value) return 0;
        if (!validate_tree(nodes, node->left)) return 0;
    }
    if (node->right != NO_CHILD) {
        if (nodes[node->right].value >= node->value) return 0;
        if (!validate_tree(nodes, node->right)) return 0;
    }
    return 1;
}

static int build_and_check_pass(int32_t selected_run, int32_t *selected_value) {
    int32_t values[ELEMENT_COUNT];
    TreeNode nodes[ELEMENT_COUNT];
    int64_t seed = 74755;
    for (int32_t i = 0; i < ELEMENT_COUNT; ++i) {
        const int32_t temp = next_random(&seed);
        values[i] = temp - (temp / 100000) * 100000 - 50000;
    }
    int32_t used = 1;
    nodes[0].value = values[0];
    nodes[0].left = nodes[0].right = NO_CHILD;
    for (int32_t i = 1; i < ELEMENT_COUNT; ++i) {
        int32_t current = 0;
        for (;;) {
            int32_t *child;
            if (values[i] > nodes[current].value) child = &nodes[current].left;
            else if (values[i] < nodes[current].value) child = &nodes[current].right;
            else break;
            if (*child == NO_CHILD) {
                *child = used;
                nodes[used].value = values[i];
                nodes[used].left = nodes[used].right = NO_CHILD;
                ++used;
                break;
            }
            current = *child;
        }
    }
    *selected_value = values[selected_run + 1];
    return validate_tree(nodes, 0);
}

static void append_text(uint8_t *buffer, size_t *used, const char *text) {
    while (*text != '\0') buffer[(*used)++] = (uint8_t)*text++;
}

static void append_integer(uint8_t *buffer, size_t *used, int32_t value) {
    uint8_t reverse[12];
    size_t count = 0;
    int32_t remaining = value;
    if (remaining < 0) { buffer[(*used)++] = (uint8_t)'-'; remaining = -remaining; }
    do {
        reverse[count++] = (uint8_t)('0' + remaining % 10);
        remaining /= 10;
    } while (remaining != 0);
    while (count > 0) buffer[(*used)++] = reverse[--count];
}

int64_t stanford_treesort(int64_t runs, uint8_t *output, size_t output_capacity) {
    if (runs < MIN_RUNS || runs > MAX_RUNS) return -1;
    if (output == NULL) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES];
    size_t used = 0;
    for (int32_t run = 0; run < (int32_t)runs; ++run) {
        int32_t selected_value = 0;
        const int valid = build_and_check_pass(run, &selected_value);
        append_integer(staged, &used, selected_value);
        append_text(staged, &used, "\n");
        if (!valid) append_text(staged, &used, " Error in Tree.\n");
    }
    if (output_capacity < used) return -2;
    for (size_t i = 0; i < used; ++i) output[i] = staged[i];
    return (int64_t)used;
}
