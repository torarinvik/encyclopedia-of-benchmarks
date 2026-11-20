module interval_tree_point_stabbing;

const long MAX_N = 16;
const long MAX_Q = 8;
const long TREE_CAP = 32;
const long MAX_INPUT = 43;
const long MAX_OUTPUT = 72;

struct Interval { long low; long high; long id; }

fn void write_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (uint8)(bits >> (byte * 8));
}

fn long interval_tree_point_stabbing(long* input, usz length, uint8* output, usz capacity)
    @export("interval_tree_point_stabbing") {
    if (input == null || length < 2 || length > MAX_INPUT.usz()) return -1;
    long n64 = input[0], q64 = input[1];
    if (n64 < 0 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q) return -1;
    long n = n64, q = q64;
    if (length != (2 + 2 * n + q).usz()) return -1;
    Interval[MAX_N] sorted;
    for (long i = 0; i < MAX_N; i++) sorted[i] = {0, 0, 0};
    usz at = 2;
    for (long i = 0; i < n; i++) {
        long low = input[at], high = input[at + 1]; at += 2;
        if (low < -32 || low > 32 || high < -32 || high > 32 || low > high) return -1;
        sorted[i] = {low, high, i};
    }
    long[MAX_Q] points;
    for (long i = 0; i < MAX_Q; i++) points[i] = 0;
    for (long i = 0; i < q; i++) {
        points[i] = input[at]; at++;
        if (points[i] < -32 || points[i] > 32) return -1;
    }
    for (long i = 1; i < n; i++) {
        Interval value = sorted[i];
        long j = i;
        while (j > 0) {
            Interval prev = sorted[j - 1];
            bool greater = prev.low > value.low ||
                (prev.low == value.low && prev.high > value.high) ||
                (prev.low == value.low && prev.high == value.high && prev.id > value.id);
            if (!greater) break;
            sorted[j] = prev; j--;
        }
        sorted[j] = value;
    }
    Interval[TREE_CAP] tree;
    bool[TREE_CAP] used;
    long[TREE_CAP] maxima;
    long[MAX_N] firsts, lasts;
    long[TREE_CAP] nodes;
    for (long i = 0; i < TREE_CAP; i++) {
        tree[i] = {0, 0, 0}; used[i] = false; maxima[i] = -9223372036854775807L - 1;
    }
    if (n > 0) {
        long top = 1; firsts[0] = 0; lasts[0] = n - 1; nodes[0] = 0;
        while (top > 0) {
            top--;
            long first = firsts[top], last = lasts[top], node = nodes[top];
            if (first > last || node >= TREE_CAP) continue;
            long middle = first + (last - first) / 2;
            tree[node] = sorted[middle]; used[node] = true;
            if (middle + 1 <= last) { firsts[top] = middle + 1; lasts[top] = last; nodes[top] = 2 * node + 2; top++; }
            if (first <= middle - 1) { firsts[top] = first; lasts[top] = middle - 1; nodes[top] = 2 * node + 1; top++; }
        }
    }
    for (long node = TREE_CAP - 1; node >= 0; node--) {
        if (!used[node]) continue;
        maxima[node] = tree[node].high;
        long left = 2 * node + 1, right = left + 1;
        if (left < TREE_CAP && used[left] && maxima[left] > maxima[node]) maxima[node] = maxima[left];
        if (right < TREE_CAP && used[right] && maxima[right] > maxima[node]) maxima[node] = maxima[right];
    }
    long[MAX_Q] masks;
    for (long i = 0; i < MAX_Q; i++) masks[i] = 0;
    for (long qi = 0; qi < q; qi++) {
        long[TREE_CAP] stack;
        long top = 0;
        if (n > 0) { stack[0] = 0; top = 1; }
        while (top > 0) {
            top--;
            long node = stack[top];
            if (!used[node] || maxima[node] < points[qi]) continue;
            long left = 2 * node + 1, right = left + 1;
            if (left < TREE_CAP && used[left] && maxima[left] >= points[qi]) { stack[top] = left; top++; }
            if (tree[node].low <= points[qi] && points[qi] <= tree[node].high)
                masks[qi] |= (long)(1UL << (ulong)tree[node].id);
            if (tree[node].low <= points[qi] && right < TREE_CAP && used[right] && maxima[right] >= points[qi]) { stack[top] = right; top++; }
        }
    }
    usz bytes = (q + 1).usz() * 8;
    if (output == null || capacity < bytes) return -2;
    uint8[MAX_OUTPUT] staged;
    for (usz i = 0; i < MAX_OUTPUT.usz(); i++) staged[i] = 0;
    write_le(&staged[0], 0, q);
    for (long i = 0; i < q; i++) write_le(&staged[0], (i + 1).usz() * 8, masks[i]);
    for (usz i = 0; i < bytes; i++) output[i] = staged[i];
    return bytes.long();
}
