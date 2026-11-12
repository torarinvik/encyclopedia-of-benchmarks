module kinetic_tournament_tree;

const usz N = 8, M = 32, BASE = 8, INPUT_MAX = 2 + 2*N + 4*M;
const long INF = 1L << 60;
struct KttNode { bool valid; usz winner; long best; long lazy; long deadline; }
struct KttOp { long kind; long left; long right; long delta; }

fn long ktt_min(long a, long b) { return a < b ? a : b; }
fn void ktt_pull(KttNode[2*BASE]* tree, usz node, long[N]* slope) {
    usz left = 2*node, right = left+1;
    if (!tree[left].valid && !tree[right].valid) { tree[node].valid = false; tree[node].deadline = INF; return; }
    if (!tree[left].valid || !tree[right].valid) {
        usz child = tree[right].valid ? right : left;
        tree[node].valid = true; tree[node].winner = tree[child].winner;
        tree[node].best = tree[child].best; tree[node].deadline = tree[child].deadline; return;
    }
    usz li = tree[left].winner, ri = tree[right].winner;
    bool choose_left = tree[left].best > tree[right].best ||
        (tree[left].best == tree[right].best && slope[li] > slope[ri]);
    usz win = choose_left ? left : right, lose = choose_left ? right : left;
    usz wi = tree[win].winner, lo = tree[lose].winner;
    long crossing = INF;
    if (slope[wi] < slope[lo]) {
        long gap = tree[win].best - tree[lose].best;
        long slope_gap = slope[lo] - slope[wi];
        crossing = gap <= 0 ? 0 : (gap + slope_gap - 1) / slope_gap;
    }
    tree[node].valid = true; tree[node].winner = wi; tree[node].best = tree[win].best;
    tree[node].deadline = ktt_min(crossing, ktt_min(tree[left].deadline, tree[right].deadline));
}
fn void ktt_apply(KttNode[2*BASE]* tree, usz node, long[N]* slope, long delta) {
    if (!tree[node].valid) return;
    tree[node].best += slope[tree[node].winner]*delta;
    tree[node].lazy += delta; tree[node].deadline -= delta;
}
fn void ktt_push(KttNode[2*BASE]* tree, usz node, long[N]* slope) {
    long delta = tree[node].lazy;
    if (delta == 0 || node >= BASE) return;
    ktt_apply(tree, 2*node, slope, delta); ktt_apply(tree, 2*node+1, slope, delta);
    tree[node].lazy = 0;
}
fn void ktt_repair(KttNode[2*BASE]* tree, usz node, long[N]* slope) {
    if (node >= BASE || !tree[node].valid) return;
    ktt_push(tree, node, slope);
    if (tree[2*node].valid && tree[2*node].deadline <= 0) ktt_repair(tree, 2*node, slope);
    if (tree[2*node+1].valid && tree[2*node+1].deadline <= 0) ktt_repair(tree, 2*node+1, slope);
    ktt_pull(tree, node, slope);
}
fn void ktt_translate(KttNode[2*BASE]* tree, usz node, usz lo, usz hi, usz ql, usz qr,
                      long delta, long[N]* slope) {
    if (ql <= lo && hi <= qr) { ktt_apply(tree, node, slope, delta); ktt_repair(tree, node, slope); return; }
    ktt_push(tree, node, slope); usz mid = (lo+hi)/2;
    if (ql < mid) ktt_translate(tree, 2*node, lo, mid, ql, qr, delta, slope);
    if (mid < qr) ktt_translate(tree, 2*node+1, mid, hi, ql, qr, delta, slope);
    ktt_pull(tree, node, slope);
}
fn long ktt_query(KttNode[2*BASE]* tree, usz node, usz lo, usz hi, usz ql, usz qr, long[N]* slope) {
    if (ql <= lo && hi <= qr) return tree[node].best;
    ktt_push(tree, node, slope); usz mid = (lo+hi)/2; long answer = -9223372036854775807L-1;
    if (ql < mid) answer = ktt_query(tree, 2*node, lo, mid, ql, qr, slope);
    if (mid < qr) { long other = ktt_query(tree, 2*node+1, mid, hi, ql, qr, slope); if (other > answer) answer = other; }
    ktt_pull(tree, node, slope); return answer;
}
fn void ktt_store(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i += 1) output[offset+i] = (uint8)((bits >> (8*i)) & 255);
}

fn long kinetic_tournament_tree(long* input, usz length, uint8* output, usz capacity)
    @export("kinetic_tournament_tree") {
    if (input == null || length < 2 || length > INPUT_MAX) return -1;
    long nr = input[0], mr = input[1];
    if (nr < 1 || nr > (long)N || mr < 1 || mr > (long)M) return -1;
    usz n = (usz)nr, m = (usz)mr, cursor = 2;
    long[N] slope = zeroed, intercept = zeroed;
    for (usz i = 0; i < n; i += 1) {
        if (cursor+2 > length) return -1;
        slope[i] = input[cursor++]; intercept[i] = input[cursor++];
        if (slope[i] < -8 || slope[i] > 8 || intercept[i] < -64 || intercept[i] > 64 || (i > 0 && slope[i] <= slope[i-1])) return -1;
    }
    KttOp[M] operations = zeroed; usz query_count = 0;
    for (usz i = 0; i < m; i += 1) {
        if (cursor >= length) return -1;
        long kind = input[cursor++];
        if (kind == 0) {
            if (cursor+3 > length) return -1;
            long left = input[cursor++], right = input[cursor++], delta = input[cursor++];
            if (left < 0 || left > right || right >= nr || delta < 1 || delta > 8) return -1;
            operations[i] = {kind,left,right,delta};
        } else if (kind == 1) {
            if (cursor+2 > length) return -1;
            long left = input[cursor++], right = input[cursor++];
            if (left < 0 || left > right || right >= nr) return -1;
            operations[i] = {kind,left,right,0}; query_count += 1;
        } else return -1;
    }
    if (cursor != length || query_count == 0) return -1;
    usz required = 8*query_count;
    if (output == null || capacity < required) return -2;
    KttNode[2*BASE] tree = zeroed;
    for (usz i = 0; i < 2*BASE; i += 1) tree[i].deadline = INF;
    for (usz i = 0; i < n; i += 1) { usz node = BASE+i; tree[node].valid = true; tree[node].winner = i; tree[node].best = intercept[i]; }
    for (usz node = BASE-1; node > 0; node -= 1) ktt_pull(&tree, node, &slope);
    long[M] answers = zeroed; usz answer_count = 0;
    for (usz i = 0; i < m; i += 1) {
        KttOp op = operations[i];
        if (op.kind == 0) ktt_translate(&tree, 1, 0, BASE, (usz)op.left, (usz)op.right+1, op.delta, &slope);
        else answers[answer_count++] = ktt_query(&tree, 1, 0, BASE, (usz)op.left, (usz)op.right+1, &slope);
    }
    for (usz i = 0; i < answer_count; i += 1) ktt_store(output, 8*i, answers[i]);
    return (long)required;
}
