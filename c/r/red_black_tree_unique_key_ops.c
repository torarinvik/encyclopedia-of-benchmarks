/* Unique-key red-black-tree insert/search/delete trace with normalized output. */
#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 128
#define NIL 0
typedef struct { int64_t key; int left, right, parent; int red; } RBNode;

static void left_rotate(RBNode *t, int *root, int x) {
    int y = t[x].right; t[x].right = t[y].left;
    if (t[y].left != NIL) t[t[y].left].parent = x;
    t[y].parent = t[x].parent;
    if (t[x].parent == NIL) *root = y;
    else if (x == t[t[x].parent].left) t[t[x].parent].left = y;
    else t[t[x].parent].right = y;
    t[y].left = x; t[x].parent = y;
}
static void right_rotate(RBNode *t, int *root, int y) {
    int x = t[y].left; t[y].left = t[x].right;
    if (t[x].right != NIL) t[t[x].right].parent = y;
    t[x].parent = t[y].parent;
    if (t[y].parent == NIL) *root = x;
    else if (y == t[t[y].parent].right) t[t[y].parent].right = x;
    else t[t[y].parent].left = x;
    t[x].right = y; t[y].parent = x;
}
static int find_node(const RBNode *t, int root, int64_t key) {
    while (root != NIL && t[root].key != key) root = key < t[root].key ? t[root].left : t[root].right;
    return root;
}
static void insert_node(RBNode *t, int *root, int z) {
    int y = NIL, x = *root;
    while (x != NIL) { y = x; x = t[z].key < t[x].key ? t[x].left : t[x].right; }
    t[z].parent = y;
    if (y == NIL) *root = z;
    else if (t[z].key < t[y].key) t[y].left = z; else t[y].right = z;
    t[z].left = t[z].right = NIL; t[z].red = 1;
    while (t[t[z].parent].red) {
        if (t[z].parent == t[t[t[z].parent].parent].left) {
            y = t[t[t[z].parent].parent].right;
            if (t[y].red) { t[t[z].parent].red = 0; t[y].red = 0; t[t[t[z].parent].parent].red = 1; z = t[t[z].parent].parent; }
            else { if (z == t[t[z].parent].right) { z = t[z].parent; left_rotate(t, root, z); }
                t[t[z].parent].red = 0; t[t[t[z].parent].parent].red = 1; right_rotate(t, root, t[t[z].parent].parent); }
        } else {
            y = t[t[t[z].parent].parent].left;
            if (t[y].red) { t[t[z].parent].red = 0; t[y].red = 0; t[t[t[z].parent].parent].red = 1; z = t[t[z].parent].parent; }
            else { if (z == t[t[z].parent].left) { z = t[z].parent; right_rotate(t, root, z); }
                t[t[z].parent].red = 0; t[t[t[z].parent].parent].red = 1; left_rotate(t, root, t[t[z].parent].parent); }
        }
    }
    t[*root].red = 0;
}
static int minimum(const RBNode *t, int x) { while (t[x].left != NIL) x = t[x].left; return x; }
static void transplant(RBNode *t, int *root, int u, int v) {
    if (t[u].parent == NIL) *root = v;
    else if (u == t[t[u].parent].left) t[t[u].parent].left = v; else t[t[u].parent].right = v;
    t[v].parent = t[u].parent;
}
static void delete_fix(RBNode *t, int *root, int x) {
    while (x != *root && !t[x].red) {
        if (x == t[t[x].parent].left) {
            int w = t[t[x].parent].right;
            if (t[w].red) { t[w].red = 0; t[t[x].parent].red = 1; left_rotate(t, root, t[x].parent); w = t[t[x].parent].right; }
            if (!t[t[w].left].red && !t[t[w].right].red) { t[w].red = 1; x = t[x].parent; }
            else { if (!t[t[w].right].red) { t[t[w].left].red = 0; t[w].red = 1; right_rotate(t, root, w); w = t[t[x].parent].right; }
                t[w].red = t[t[x].parent].red; t[t[x].parent].red = 0; t[t[w].right].red = 0; left_rotate(t, root, t[x].parent); x = *root; }
        } else {
            int w = t[t[x].parent].left;
            if (t[w].red) { t[w].red = 0; t[t[x].parent].red = 1; right_rotate(t, root, t[x].parent); w = t[t[x].parent].left; }
            if (!t[t[w].right].red && !t[t[w].left].red) { t[w].red = 1; x = t[x].parent; }
            else { if (!t[t[w].left].red) { t[t[w].right].red = 0; t[w].red = 1; left_rotate(t, root, w); w = t[t[x].parent].left; }
                t[w].red = t[t[x].parent].red; t[t[x].parent].red = 0; t[t[w].left].red = 0; right_rotate(t, root, t[x].parent); x = *root; }
        }
    }
    t[x].red = 0;
}
static void delete_node(RBNode *t, int *root, int z) {
    int y = z, x, was_red = t[y].red;
    if (t[z].left == NIL) { x = t[z].right; transplant(t, root, z, t[z].right); }
    else if (t[z].right == NIL) { x = t[z].left; transplant(t, root, z, t[z].left); }
    else { y = minimum(t, t[z].right); was_red = t[y].red; x = t[y].right;
        if (t[y].parent == z) t[x].parent = y;
        else { transplant(t, root, y, t[y].right); t[y].right = t[z].right; t[t[y].right].parent = y; }
        transplant(t, root, z, y); t[y].left = t[z].left; t[t[y].left].parent = y; t[y].red = t[z].red;
    }
    if (!was_red) delete_fix(t, root, x);
}
static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[offset + i] = (uint8_t)(bits >> (8 * i));
}
int64_t red_black_tree_unique_key_ops(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 1) return -1;
    int64_t n64 = input[0];
    if (n64 < 0 || n64 > MAX_OPS || length != 1 + 2 * (size_t)n64) return -1;
    size_t n = (size_t)n64, active_count = 0, search_count = 0;
    int64_t active[MAX_OPS];
    for (size_t i = 0; i < n; ++i) {
        int64_t op = input[1 + 2*i], key = input[2 + 2*i];
        if (op < 0 || op > 2 || key < INT32_MIN || key > INT32_MAX) return -1;
        size_t found = active_count;
        for (size_t j = 0; j < active_count; ++j) if (active[j] == key) { found = j; break; }
        if (op == 0) { if (found != active_count || active_count >= MAX_OPS) return -1; active[active_count++] = key; }
        else if (op == 1) ++search_count;
        else { if (found == active_count) return -1; for (size_t j = found + 1; j < active_count; ++j) active[j-1] = active[j]; --active_count; }
    }
    RBNode t[MAX_OPS + 1] = {0}; int root = NIL, next = 1;
    int64_t results[MAX_OPS]; size_t result_count = 0;
    for (size_t i = 0; i < n; ++i) {
        int64_t op = input[1 + 2*i], key = input[2 + 2*i];
        if (op == 0) { t[next].key = key; insert_node(t, &root, next++); }
        else if (op == 1) results[result_count++] = find_node(t, root, key) != NIL;
        else delete_node(t, &root, find_node(t, root, key));
    }
    size_t bytes = (2 + active_count + search_count) * 8;
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, (int64_t)active_count);
    int stack[MAX_OPS], top = 0, current = root; size_t out = 1;
    while (current != NIL || top > 0) { while (current != NIL) { stack[top++] = current; current = t[current].left; }
        current = stack[--top]; put_i64(output, out++ * 8, t[current].key); current = t[current].right; }
    put_i64(output, out++ * 8, (int64_t)search_count);
    for (size_t i = 0; i < search_count; ++i) put_i64(output, out++ * 8, results[i]);
    return (int64_t)bytes;
}
