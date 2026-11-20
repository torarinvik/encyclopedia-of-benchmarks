#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MAX_N = 20, MAX_M = 32, MAX_INPUT = 35, MAX_NODES = 128, MAX_OUT = 648 };
enum { LEAF = 0, P_NODE = 1, Q_NODE = 2, WHITE = 0, BLACK = 1, MIXED = 2 };

typedef struct { uint8_t kind, count, arg, child[MAX_N]; } Node;
typedef struct {
    Node node[MAX_NODES];
    uint8_t color[MAX_NODES], free_id[MAX_NODES];
    int next_id, free_count, root, n;
} Tree;

static int create(Tree *t, int kind) {
    int id;
    if (t->free_count) id = t->free_id[--t->free_count];
    else { if (t->next_id >= MAX_NODES) return -1; id = t->next_id++; }
    memset(&t->node[id], 0, sizeof(t->node[id]));
    t->node[id].kind = (uint8_t)kind;
    return id;
}
static void discard(Tree *t, int id) { t->node[id].count = 0; t->free_id[t->free_count++] = (uint8_t)id; }
static void push(Node *node, int child) { node->child[node->count++] = (uint8_t)child; }

static int paint(Tree *t, int id, uint64_t mask) {
    Node *u = &t->node[id];
    if (u->kind == LEAF) {
        t->color[id] = (uint8_t)(((mask >> u->arg) & 1u) ? BLACK : WHITE);
        return t->color[id];
    }
    int saw_white = 0, saw_black = 0;
    for (int i = 0; i < u->count; ++i) {
        int shade = paint(t, u->child[i], mask);
        saw_white |= shade != BLACK;
        saw_black |= shade != WHITE;
    }
    t->color[id] = (uint8_t)(saw_white && saw_black ? MIXED : saw_black ? BLACK : WHITE);
    return t->color[id];
}

static int q_pattern(Tree *t, const uint8_t *children, int count) {
    int pivot = -1, mixed = 0;
    for (int i = 0; i < count; ++i) if (t->color[children[i]] == MIXED) {
        pivot = i;
        if (++mixed > 1) return 0;
    }
    if (!mixed) {
        for (int i = 0; i < count; ++i) if (t->color[children[i]] == BLACK) { pivot = i; break; }
    }
    if (pivot < 0) return 0;
    for (int i = 0; i < pivot; ++i) if (t->color[children[i]] != WHITE) return 0;
    for (int i = pivot + 1; i < count; ++i) if (t->color[children[i]] != BLACK) return 0;
    return 1;
}

static int split(Tree *t, int id, uint8_t *out, int *out_count) {
    Node *u = &t->node[id];
    if (t->color[id] != MIXED) { out[0] = (uint8_t)id; *out_count = 1; return 1; }
    uint8_t old[MAX_N], white[MAX_N], black[MAX_N], mixed[MAX_N];
    int old_count = u->count, nw = 0, nb = 0, nm = 0;
    for (int i = 0; i < old_count; ++i) {
        old[i] = u->child[i];
        int shade = t->color[old[i]];
        if (shade == WHITE) white[nw++] = old[i];
        else if (shade == BLACK) black[nb++] = old[i];
        else mixed[nm++] = old[i];
    }
    int used = 0;
    if (u->kind == Q_NODE) {
        if (!q_pattern(t, old, old_count)) {
            for (int l = 0, r = old_count - 1; l < r; ++l, --r) { uint8_t x = old[l]; old[l] = old[r]; old[r] = x; }
            if (!q_pattern(t, old, old_count)) return 0;
        }
        for (int i = 0; i < old_count; ++i) {
            if (t->color[old[i]] == MIXED) {
                uint8_t part[MAX_N]; int part_count = 0;
                if (!split(t, old[i], part, &part_count)) return 0;
                for (int j = 0; j < part_count; ++j) out[used++] = part[j];
            } else out[used++] = old[i];
        }
    } else {
        if (nm > 1) return 0;
        if (nw) {
            int group = create(t, P_NODE); if (group < 0) return 0;
            for (int i = 0; i < nw; ++i) push(&t->node[group], white[i]);
            out[used++] = (uint8_t)group;
        }
        if (nm) {
            uint8_t part[MAX_N]; int part_count = 0;
            if (!split(t, mixed[0], part, &part_count)) return 0;
            for (int i = 0; i < part_count; ++i) out[used++] = part[i];
        }
        if (nb) {
            int group = create(t, P_NODE); if (group < 0) return 0;
            for (int i = 0; i < nb; ++i) push(&t->node[group], black[i]);
            out[used++] = (uint8_t)group;
        }
    }
    discard(t, id);
    *out_count = used;
    return 1;
}

static int work(Tree *t, int id) {
    Node *u = &t->node[id];
    if (t->color[id] != MIXED) return 1;
    uint8_t old[MAX_N], white[MAX_N], black[MAX_N], mixed[MAX_N];
    int old_count = u->count, nw = 0, nb = 0, nm = 0;
    for (int i = 0; i < old_count; ++i) {
        old[i] = u->child[i];
        int shade = t->color[old[i]];
        if (shade == WHITE) white[nw++] = old[i];
        else if (shade == BLACK) black[nb++] = old[i];
        else mixed[nm++] = old[i];
    }
    if (u->kind == P_NODE) {
            if (nb == 0 && nm == 1) return work(t, mixed[0]);
        if (nm > 2) return 0;
        int q = create(t, Q_NODE); if (q < 0) return 0;
        int root_count = 0;
        for (int i = 0; i < nw; ++i) u->child[root_count++] = white[i];
        u->child[root_count++] = (uint8_t)q;
        u->count = (uint8_t)root_count;
        if (nm) {
            uint8_t part[MAX_N]; int part_count = 0;
            if (!split(t, mixed[0], part, &part_count)) return 0;
            for (int i = 0; i < part_count; ++i) push(&t->node[q], part[i]);
        }
        if (nb) {
            int group = create(t, P_NODE); if (group < 0) return 0;
            for (int i = 0; i < nb; ++i) push(&t->node[group], black[i]);
            push(&t->node[q], group);
        }
        if (nm == 2) {
            uint8_t part[MAX_N]; int part_count = 0;
            if (!split(t, mixed[1], part, &part_count)) return 0;
            for (int i = part_count - 1; i >= 0; --i) push(&t->node[q], part[i]);
        }
        return 1;
    }

    int left = -1, right = -1;
    for (int i = 0; i < old_count; ++i) if (t->color[old[i]] != WHITE) {
        if (left < 0) left = i;
        right = i;
    }
    if (left < 0) return 0;
    for (int i = left + 1; i < right; ++i) if (t->color[old[i]] != BLACK) return 0;
    if (left == right && t->color[old[left]] == MIXED) return work(t, old[left]);
    uint8_t result[MAX_N]; int used = 0;
    for (int i = 0; i < left; ++i) result[used++] = old[i];
    uint8_t part[MAX_N]; int part_count = 0;
    if (!split(t, old[left], part, &part_count)) return 0;
    for (int i = 0; i < part_count; ++i) result[used++] = part[i];
    for (int i = left + 1; i < right; ++i) result[used++] = old[i];
    if (right != left) {
        part_count = 0;
        if (!split(t, old[right], part, &part_count)) return 0;
        for (int i = part_count - 1; i >= 0; --i) result[used++] = part[i];
    }
    for (int i = right + 1; i < old_count; ++i) result[used++] = old[i];
    u->count = (uint8_t)used;
    for (int i = 0; i < used; ++i) u->child[i] = result[i];
    return 1;
}

static int normalize(Tree *t, int id) {
    Node *u = &t->node[id];
    if (u->kind == LEAF) return id;
    for (int i = 0; i < u->count; ++i) u->child[i] = (uint8_t)normalize(t, u->child[i]);
    if (u->count == 1) { int child = u->child[0]; discard(t, id); return child; }
    if (u->kind == Q_NODE && u->count == 2) u->kind = P_NODE;
    return id;
}

static int compare(Tree *t, int a, int b) {
    Node *x = &t->node[a], *y = &t->node[b];
    int xa = x->kind == LEAF ? x->arg : x->count, ya = y->kind == LEAF ? y->arg : y->count;
    if (x->kind != y->kind) return x->kind < y->kind ? -1 : 1;
    if (xa != ya) return xa < ya ? -1 : 1;
    if (x->kind == LEAF) return 0;
    int limit = x->count < y->count ? x->count : y->count;
    for (int i = 0; i < limit; ++i) { int c = compare(t, x->child[i], y->child[i]); if (c) return c; }
    return (x->count > y->count) - (x->count < y->count);
}

static void canonicalize(Tree *t, int id) {
    Node *u = &t->node[id]; if (u->kind == LEAF) return;
    for (int i = 0; i < u->count; ++i) canonicalize(t, u->child[i]);
    if (u->kind == P_NODE) {
        for (int i = 1; i < u->count; ++i) {
            uint8_t item = u->child[i]; int j = i;
            while (j > 0 && compare(t, item, u->child[j - 1]) < 0) { u->child[j] = u->child[j - 1]; --j; }
            u->child[j] = item;
        }
    } else {
        int order = 0;
        for (int i = 0; i < u->count; ++i) { int c = compare(t, u->child[i], u->child[u->count - 1 - i]); if (c) { order = c; break; } }
        if (order > 0) for (int l = 0, r = u->count - 1; l < r; ++l, --r) { uint8_t x = u->child[l]; u->child[l] = u->child[r]; u->child[r] = x; }
    }
}

static int64_t frontier_count(Tree *t, int id) {
    Node *u = &t->node[id]; if (u->kind == LEAF) return 1;
    int64_t result = 1;
    for (int i = 0; i < u->count; ++i) result *= frontier_count(t, u->child[i]);
    if (u->kind == P_NODE) for (int i = 2; i <= u->count; ++i) result *= i;
    else result *= 2;
    return result;
}
static int subtree_nodes(Tree *t, int id) {
    Node *u = &t->node[id]; int result = 1;
    for (int i = 0; i < u->count && u->kind != LEAF; ++i) result += subtree_nodes(t, u->child[i]);
    return result;
}
static void serialize(Tree *t, int id, int64_t *words, int *used) {
    Node *u = &t->node[id]; words[(*used)++] = u->kind; words[(*used)++] = u->kind == LEAF ? u->arg : u->count;
    for (int i = 0; i < u->count && u->kind != LEAF; ++i) serialize(t, u->child[i], words, used);
}
static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) out[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t pq_tree_consecutive_ones(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t n_raw = input[0], m_raw = input[1];
    if (n_raw < 2 || n_raw > MAX_N || m_raw < 0 || m_raw > MAX_M || length != (size_t)(2 + m_raw)) return -1;
    int n = (int)n_raw, m = (int)m_raw;
    uint64_t valid = (UINT64_C(1) << n) - 1;
    for (int row = 0; row < m; ++row) if (input[2 + row] < 0 || ((uint64_t)input[2 + row] & ~valid) != 0) return -1;

    Tree t = {0}; t.n = n; t.next_id = n + 1; t.root = n;
    for (int i = 0; i < n; ++i) { t.node[i].kind = LEAF; t.node[i].arg = (uint8_t)i; }
    t.node[t.root].kind = P_NODE; t.node[t.root].count = (uint8_t)n;
    for (int i = 0; i < n; ++i) t.node[t.root].child[i] = (uint8_t)i;
    for (int row = 0; row < m; ++row) {
        paint(&t, t.root, (uint64_t)input[2 + row]);
        if (!work(&t, t.root)) {
            int64_t words[3] = {0, 0, 0}; uint8_t staged[24];
            for (int i = 0; i < 3; ++i) store_i64_le(staged, (size_t)i * 8, words[i]);
            if (output == NULL || capacity < sizeof(staged)) return -2;
            for (size_t i = 0; i < sizeof(staged); ++i) output[i] = staged[i];
            return (int64_t)sizeof(staged);
        }
        t.root = normalize(&t, t.root);
    }
    canonicalize(&t, t.root);
    int64_t words[81]; int used = 0;
    words[used++] = 1; words[used++] = frontier_count(&t, t.root); words[used++] = subtree_nodes(&t, t.root);
    serialize(&t, t.root, words, &used);
    uint8_t staged[MAX_OUT];
    for (int i = 0; i < used; ++i) store_i64_le(staged, (size_t)i * 8, words[i]);
    size_t bytes = (size_t)used * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
