module fractional_cascading_subset_chain;

const MAX_M = 8;
const MAX_Q = 8;
const MAX_N = 16;
const MAX_LEN = 147;
const NO_SUCCESSOR = 34;

fn long fractional_cascading_subset_chain(long* input, usz length) @export("fractional_cascading_subset_chain") {
    if (input == null || length < 2 || length > MAX_LEN) return -1;
    if (input[0] < 2 || input[0] > MAX_M || input[1] < 1 || input[1] > MAX_Q) return -1;
    usz m = (usz)input[0], q = (usz)input[1], cursor = 2;
    long[MAX_M][MAX_N] catalogs = zeroed;
    usz[MAX_M] sizes = zeroed;
    long[MAX_Q] queries = zeroed;
    for (usz i = 0; i < m; i++) {
        if (cursor >= length || input[cursor] < 1 || input[cursor] > MAX_N) return -1;
        usz n = (usz)input[cursor++];
        if (cursor + n > length) return -1;
        sizes[i] = n;
        for (usz j = 0; j < n; j++) {
            long key = input[cursor++];
            if (key < -16 || key > 16 || (j > 0 && catalogs[i][j - 1] >= key)) return -1;
            catalogs[i][j] = key;
        }
        if (i > 0) {
            usz p = 0, c = 0;
            while (p < sizes[i - 1] && c < n) {
                if (catalogs[i - 1][p] < catalogs[i][c]) p++;
                else if (catalogs[i - 1][p] == catalogs[i][c]) { p++; c++; }
                else return -1;
            }
            if (c != n) return -1;
        }
    }
    if (cursor + q != length) return -1;
    for (usz i = 0; i < q; i++) { queries[i] = input[cursor++]; if (queries[i] < -17 || queries[i] > 17) return -1; }

    usz[MAX_M - 1][MAX_N + 1] bridge = zeroed;
    for (usz i = 0; i + 1 < m; i++) {
        usz child = 0;
        for (usz slot = 0; slot < sizes[i]; slot++) {
            while (child < sizes[i + 1] && catalogs[i + 1][child] < catalogs[i][slot]) child++;
            bridge[i][slot] = child;
        }
        bridge[i][sizes[i]] = sizes[i + 1];
    }
    long checksum = 0;
    for (usz qi = 0; qi < q; qi++) {
        usz low = 0, high = sizes[0];
        while (low < high) {
            usz mid = (low + high) / 2;
            if (catalogs[0][mid] < queries[qi]) low = mid + 1; else high = mid;
        }
        usz slot = low;
        for (usz ci = 0; ci < m; ci++) {
            long code = slot < sizes[ci] ? catalogs[ci][slot] + 17 : NO_SUCCESSOR;
            checksum += (long)(qi + 1) * (long)(ci + 1) * code;
            if (ci + 1 < m) slot = bridge[ci][slot];
        }
    }
    return checksum;
}
