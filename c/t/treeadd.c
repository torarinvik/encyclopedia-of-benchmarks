#include <stdint.h>

#define TREEADD_MAX_LEVEL 12
#define TREEADD_MAX_NODES ((1 << TREEADD_MAX_LEVEL) - 1)
#define TREEADD_PASSES 100

typedef struct {
    int32_t value;
    int32_t left;
    int32_t right;
} treeadd_node;

static int32_t treeadd_alloc(treeadd_node *nodes, int32_t *used,
                             int32_t level, int32_t lo, int32_t proc) {
    if (level == 0) return -1;
    if (*used >= TREEADD_MAX_NODES) return -1;
    int32_t index = (*used)++;
    nodes[index].value = 1;
    int32_t left = treeadd_alloc(nodes, used, level - 1, lo + proc / 2, proc / 2);
    int32_t right = treeadd_alloc(nodes, used, level - 1, lo, proc / 2);
    nodes[index].left = left;
    nodes[index].right = right;
    return index;
}

static int64_t treeadd_sum(const treeadd_node *nodes, int32_t index) {
    if (index < 0) return 0;
    return nodes[index].value + treeadd_sum(nodes, nodes[index].left) +
           treeadd_sum(nodes, nodes[index].right);
}

int64_t treeadd(int64_t level) {
    if (level < 0 || level > TREEADD_MAX_LEVEL) return -1;
    treeadd_node nodes[TREEADD_MAX_NODES];
    int32_t used = 0;
    int32_t root = treeadd_alloc(nodes, &used, (int32_t)level, 0, 4);
    int64_t result = 0;
    for (int32_t pass = 0; pass < TREEADD_PASSES; ++pass) {
        result = treeadd_sum(nodes, root);
    }
    return result;
}
