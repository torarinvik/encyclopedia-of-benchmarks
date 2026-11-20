// Clean-room McCreight radix priority-search-tree profile.
module priority_search_tree_three_sided_reporting;
const usz PST_N = 8;
const usz PST_Q = 7;
const usz PST_X = 32;

fn long priority_search_tree_three_sided_reporting(long* input, usz length) @export("priority_search_tree_three_sided_reporting") {
    if (input == null || length < 2 || length > 48) return -1;
    long n64 = input[0], q64 = input[1];
    if (n64 < 0 || n64 > 8 || q64 < 0 || q64 > 7 || length != 2 + 3 * (usz)n64 + 3 * (usz)q64) return -1;
    usz n = (usz)n64, q = (usz)q64, at = 2;
    long[PST_N] nx, ny, nl, nlo, nhi;
    int[PST_N] left, right;
    bool[PST_X] seen_x = zeroed;
    bool[PST_N] seen_label = zeroed;
    for (usz i = 0; i < PST_N; i++) { left[i] = -1; right[i] = -1; }
    int root = -1, node_count = 0;
    for (usz r = 0; r < n; r++) {
        long x64 = input[at], y64 = input[at + 1], label64 = input[at + 2]; at += 3;
        if (x64 < 0 || x64 >= 32 || y64 < -64 || y64 > 63 || label64 < 0 || label64 >= 8) return -1;
        usz x = (usz)x64, label = (usz)label64;
        if (seen_x[x] || seen_label[label]) return -1;
        seen_x[x] = true; seen_label[label] = true;
        long px = x64, py = y64, plabel = label64;
        if (root < 0) {
            root = node_count; node_count += 1;
            nx[root] = px; ny[root] = py; nl[root] = plabel; nlo[root] = 0; nhi[root] = 32;
            continue;
        }
        int cur = root; usz low = 0, high = 32;
        while (true) {
            if (py < ny[cur]) {
                long tmp = nx[cur]; nx[cur] = px; px = tmp;
                tmp = ny[cur]; ny[cur] = py; py = tmp;
                tmp = nl[cur]; nl[cur] = plabel; plabel = tmp;
            }
            usz mid = (low + high) / 2;
            if (px < (long)mid) {
                if (left[cur] < 0) {
                    int child = node_count; node_count += 1; left[cur] = child;
                    nx[child] = px; ny[child] = py; nl[child] = plabel;
                    nlo[child] = (long)low; nhi[child] = (long)mid; break;
                }
                cur = left[cur]; high = mid;
            } else {
                if (right[cur] < 0) {
                    int child = node_count; node_count += 1; right[cur] = child;
                    nx[child] = px; ny[child] = py; nl[child] = plabel;
                    nlo[child] = (long)mid; nhi[child] = (long)high; break;
                }
                cur = right[cur]; low = mid;
            }
        }
    }
    long[PST_Q] qx0, qx1, qy1;
    for (usz i = 0; i < q; i++) {
        qx0[i] = input[at]; qx1[i] = input[at + 1]; qy1[i] = input[at + 2]; at += 3;
        if (qx0[i] < 0 || qx0[i] > qx1[i] || qx1[i] >= 32 || qy1[i] < -64 || qy1[i] > 63) return -1;
    }
    long result = 0;
    for (usz qi = 0; qi < q; qi++) {
        long mask = 0;
        if (root >= 0) {
            int[PST_N] stack; usz top = 0; stack[top] = root; top += 1;
            while (top > 0) {
                top -= 1; int node = stack[top];
                if (qx1[qi] < nlo[node] || qx0[qi] >= nhi[node] || ny[node] > qy1[qi]) continue;
                if (qx0[qi] <= nx[node] && nx[node] <= qx1[qi]) mask |= 1 << nl[node];
                if (left[node] >= 0) { stack[top] = left[node]; top += 1; }
                if (right[node] >= 0) { stack[top] = right[node]; top += 1; }
            }
        }
        result |= mask << (8 * qi);
    }
    return result;
}
