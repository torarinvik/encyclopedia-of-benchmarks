#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { KTT_N = 8, KTT_M = 32, KTT_BASE = 8, KTT_INPUT_MAX = 2 + 2*KTT_N + 4*KTT_M };
static const int64_t KTT_INF = INT64_C(1) << 60;

typedef struct {
    bool valid;
    size_t winner;
    int64_t best;
    int64_t lazy;
    int64_t deadline;
} KttNode;
typedef struct { int64_t kind, left, right, delta; } KttOp;

static int64_t ktt_min(int64_t a, int64_t b) { return a < b ? a : b; }

static void ktt_pull(KttNode tree[2*KTT_BASE], size_t node, const int64_t slope[KTT_N]) {
    const size_t left = 2*node, right = left+1;
    if (!tree[left].valid && !tree[right].valid) {
        tree[node].valid = false;
        tree[node].deadline = KTT_INF;
        return;
    }
    if (!tree[left].valid || !tree[right].valid) {
        const size_t child = tree[right].valid ? right : left;
        tree[node].valid = true;
        tree[node].winner = tree[child].winner;
        tree[node].best = tree[child].best;
        tree[node].deadline = tree[child].deadline;
        return;
    }
    const size_t li = tree[left].winner, ri = tree[right].winner;
    const bool choose_left = tree[left].best > tree[right].best ||
        (tree[left].best == tree[right].best && slope[li] > slope[ri]);
    const size_t win = choose_left ? left : right;
    const size_t lose = choose_left ? right : left;
    const size_t wi = tree[win].winner, lo = tree[lose].winner;
    int64_t crossing = KTT_INF;
    if (slope[wi] < slope[lo]) {
        const int64_t gap = tree[win].best - tree[lose].best;
        const int64_t slope_gap = slope[lo] - slope[wi];
        crossing = gap <= 0 ? 0 : (gap + slope_gap - 1) / slope_gap;
    }
    tree[node].valid = true;
    tree[node].winner = wi;
    tree[node].best = tree[win].best;
    tree[node].deadline = ktt_min(crossing, ktt_min(tree[left].deadline, tree[right].deadline));
}

static void ktt_apply(KttNode tree[2*KTT_BASE], size_t node,
                      const int64_t slope[KTT_N], int64_t delta) {
    if (!tree[node].valid) return;
    tree[node].best += slope[tree[node].winner] * delta;
    tree[node].lazy += delta;
    tree[node].deadline -= delta;
}

static void ktt_push(KttNode tree[2*KTT_BASE], size_t node,
                     const int64_t slope[KTT_N]) {
    const int64_t delta = tree[node].lazy;
    if (delta == 0 || node >= KTT_BASE) return;
    ktt_apply(tree, 2*node, slope, delta);
    ktt_apply(tree, 2*node+1, slope, delta);
    tree[node].lazy = 0;
}

static void ktt_repair(KttNode tree[2*KTT_BASE], size_t node,
                       const int64_t slope[KTT_N]) {
    if (node >= KTT_BASE || !tree[node].valid) return;
    ktt_push(tree, node, slope);
    if (tree[2*node].valid && tree[2*node].deadline <= 0)
        ktt_repair(tree, 2*node, slope);
    if (tree[2*node+1].valid && tree[2*node+1].deadline <= 0)
        ktt_repair(tree, 2*node+1, slope);
    ktt_pull(tree, node, slope);
}

static void ktt_translate(KttNode tree[2*KTT_BASE], size_t node, size_t lo, size_t hi,
                          size_t ql, size_t qr, int64_t delta,
                          const int64_t slope[KTT_N]) {
    if (ql <= lo && hi <= qr) {
        ktt_apply(tree, node, slope, delta);
        ktt_repair(tree, node, slope);
        return;
    }
    ktt_push(tree, node, slope);
    const size_t mid = (lo + hi) / 2;
    if (ql < mid) ktt_translate(tree, 2*node, lo, mid, ql, qr, delta, slope);
    if (mid < qr) ktt_translate(tree, 2*node+1, mid, hi, ql, qr, delta, slope);
    ktt_pull(tree, node, slope);
}

static int64_t ktt_query(KttNode tree[2*KTT_BASE], size_t node, size_t lo, size_t hi,
                         size_t ql, size_t qr, const int64_t slope[KTT_N]) {
    if (ql <= lo && hi <= qr) return tree[node].best;
    ktt_push(tree, node, slope);
    const size_t mid = (lo + hi) / 2;
    int64_t answer = INT64_MIN;
    if (ql < mid) answer = ktt_query(tree, 2*node, lo, mid, ql, qr, slope);
    if (mid < qr) {
        const int64_t right = ktt_query(tree, 2*node+1, mid, hi, ql, qr, slope);
        if (right > answer) answer = right;
    }
    ktt_pull(tree, node, slope);
    return answer;
}

static void ktt_store(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset+byte] = (uint8_t)(bits >> (8*byte));
}

int64_t kinetic_tournament_tree(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > KTT_INPUT_MAX) return -1;
    const int64_t nr = input[0], mr = input[1];
    if (nr < 1 || nr > KTT_N || mr < 1 || mr > KTT_M) return -1;
    const size_t n = (size_t)nr, m = (size_t)mr;
    size_t cursor = 2;
    int64_t slope[KTT_N] = {0}, intercept[KTT_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        if (cursor+2 > length) return -1;
        slope[i] = input[cursor++]; intercept[i] = input[cursor++];
        if (slope[i] < -8 || slope[i] > 8 || intercept[i] < -64 || intercept[i] > 64 ||
            (i > 0 && slope[i] <= slope[i-1])) return -1;
    }
    KttOp operations[KTT_M] = {{0}};
    size_t query_count = 0;
    for (size_t i = 0; i < m; ++i) {
        if (cursor >= length) return -1;
        const int64_t kind = input[cursor++];
        if (kind == 0) {
            if (cursor+3 > length) return -1;
            const int64_t left = input[cursor++], right = input[cursor++], delta = input[cursor++];
            if (left < 0 || left > right || right >= nr || delta < 1 || delta > 8) return -1;
            operations[i] = (KttOp){0,left,right,delta};
        } else if (kind == 1) {
            if (cursor+2 > length) return -1;
            const int64_t left = input[cursor++], right = input[cursor++];
            if (left < 0 || left > right || right >= nr) return -1;
            operations[i] = (KttOp){1,left,right,0};
            ++query_count;
        } else return -1;
    }
    if (cursor != length || query_count == 0) return -1;
    const size_t required = 8*query_count;
    if (output == NULL || capacity < required) return -2;

    KttNode tree[2*KTT_BASE] = {{0}};
    for (size_t i = 0; i < 2*KTT_BASE; ++i) tree[i].deadline = KTT_INF;
    for (size_t i = 0; i < n; ++i) {
        const size_t node = KTT_BASE+i;
        tree[node].valid = true; tree[node].winner = i; tree[node].best = intercept[i];
    }
    for (size_t node = KTT_BASE-1; node > 0; --node) ktt_pull(tree, node, slope);
    int64_t answers[KTT_M] = {0};
    size_t answer_count = 0;
    for (size_t i = 0; i < m; ++i) {
        const KttOp op = operations[i];
        if (op.kind == 0)
            ktt_translate(tree, 1, 0, KTT_BASE, (size_t)op.left, (size_t)op.right+1, op.delta, slope);
        else
            answers[answer_count++] = ktt_query(tree, 1, 0, KTT_BASE,
                (size_t)op.left, (size_t)op.right+1, slope);
    }
    for (size_t i = 0; i < answer_count; ++i) ktt_store(output, 8*i, answers[i]);
    return (int64_t)required;
}
