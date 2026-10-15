#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 32
#define POOL_CAP 8192
#define OUT_I64_CAP 5000
typedef struct { int value, left, right, height; } Node;

static int height(const Node *pool, int id) { return id == 0 ? -1 : pool[id].height; }
static int make_node(Node *pool, int *next, int value, int left, int right) {
    const int id = (*next)++;
    pool[id] = (Node){value, left, right, 1 + (height(pool,left) > height(pool,right) ? height(pool,left) : height(pool,right))};
    return id;
}
static int balance(const Node *pool, int id) { return height(pool,pool[id].right) - height(pool,pool[id].left); }
static int rotate_right(Node *pool, int *next, int root) {
    const int left = pool[root].left;
    const int moved = make_node(pool,next,pool[root].value,pool[left].right,pool[root].right);
    return make_node(pool,next,pool[left].value,pool[left].left,moved);
}
static int rotate_left(Node *pool, int *next, int root) {
    const int right = pool[root].right;
    const int moved = make_node(pool,next,pool[root].value,pool[root].left,pool[right].left);
    return make_node(pool,next,pool[right].value,moved,pool[right].right);
}
static int rebalance(Node *pool, int *next, int root) {
    const int bf = balance(pool,root);
    if (bf > 1) {
        if (balance(pool,pool[root].right) < 0) {
            const int rotated = rotate_right(pool,next,pool[root].right);
            root = make_node(pool,next,pool[root].value,pool[root].left,rotated);
        }
        return rotate_left(pool,next,root);
    }
    if (bf < -1) {
        if (balance(pool,pool[root].left) > 0) {
            const int rotated = rotate_left(pool,next,pool[root].left);
            root = make_node(pool,next,pool[root].value,rotated,pool[root].right);
        }
        return rotate_right(pool,next,root);
    }
    return root;
}
static int insert_node(Node *pool, int *next, int root, int value) {
    if (root == 0) return make_node(pool,next,value,0,0);
    if (value == pool[root].value) return root;
    if (value < pool[root].value) return rebalance(pool,next,make_node(pool,next,pool[root].value,insert_node(pool,next,pool[root].left,value),pool[root].right));
    return rebalance(pool,next,make_node(pool,next,pool[root].value,pool[root].left,insert_node(pool,next,pool[root].right,value)));
}
static int delete_min(Node *pool, int *next, int root, int *minimum) {
    if (pool[root].left == 0) { *minimum = pool[root].value; return pool[root].right; }
    return rebalance(pool,next,make_node(pool,next,pool[root].value,delete_min(pool,next,pool[root].left,minimum),pool[root].right));
}
static int delete_node(Node *pool, int *next, int root, int value) {
    if (root == 0) return 0;
    if (value < pool[root].value) return rebalance(pool,next,make_node(pool,next,pool[root].value,delete_node(pool,next,pool[root].left,value),pool[root].right));
    if (value > pool[root].value) return rebalance(pool,next,make_node(pool,next,pool[root].value,pool[root].left,delete_node(pool,next,pool[root].right,value)));
    if (pool[root].left == 0) return pool[root].right;
    if (pool[root].right == 0) return pool[root].left;
    int successor = 0;
    const int right = delete_min(pool,next,pool[root].right,&successor);
    return rebalance(pool,next,make_node(pool,next,successor,pool[root].left,right));
}

int64_t avltree_persistent_insert_delete(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1 || input[0] < 0 || input[0] > MAX_OPS || length != 1 + 3 * (size_t)input[0]) return -1;
    const size_t operations = (size_t)input[0];
    for (size_t i = 0; i < operations; ++i) {
        const int64_t parent = input[1+3*i], op = input[2+3*i], value = input[3+3*i];
        if (parent < 0 || parent > (int64_t)i || (op != 0 && op != 1) || value < -1000 || value > 1000) return -1;
    }
    Node pool[POOL_CAP] = {{0}}; int next = 1; int roots[MAX_OPS+1] = {0};
    for (size_t i = 0; i < operations; ++i) {
        const int parent_root = roots[input[1+3*i]];
        roots[i+1] = input[2+3*i] == 0 ? insert_node(pool,&next,parent_root,(int)input[3+3*i]) : delete_node(pool,&next,parent_root,(int)input[3+3*i]);
        if (next >= POOL_CAP - 64) return -1;
    }
    int64_t packed[OUT_I64_CAP]; size_t count = 0;
    packed[count++] = (int64_t)operations + 1;
    for (size_t version = 0; version <= operations; ++version) {
        const int root = roots[version]; int queue[MAX_OPS+1], local[POOL_CAP], left_ids[MAX_OPS+1], right_ids[MAX_OPS+1];
        for (int i = 0; i < POOL_CAP; ++i) local[i] = -1;
        size_t tail = 0;
        if (root != 0) { queue[tail] = root; local[root] = 0; tail = 1; }
        for (size_t head = 0; head < tail; ++head) {
            left_ids[head] = right_ids[head] = -1;
            const int children[2] = {pool[queue[head]].left, pool[queue[head]].right};
            for (int side = 0; side < 2; ++side) if (children[side] != 0) {
                const int child = children[side];
                if (local[child] < 0) { local[child] = (int)tail; queue[tail++] = child; }
                if (side == 0) left_ids[head] = local[child]; else right_ids[head] = local[child];
            }
        }
        packed[count++] = (int64_t)tail;
        packed[count++] = height(pool,root);
        for (size_t i = 0; i < tail; ++i) {
            packed[count++] = pool[queue[i]].value; packed[count++] = pool[queue[i]].height;
            packed[count++] = left_ids[i]; packed[count++] = right_ids[i];
        }
    }
    const size_t required = count * 8;
    if (!output || capacity < required) return -2;
    for (size_t i = 0; i < count; ++i) { const uint64_t bits = (uint64_t)packed[i]; for (size_t b = 0; b < 8; ++b) output[8*i+b] = (uint8_t)(bits >> (8*b)); }
    return (int64_t)required;
}
