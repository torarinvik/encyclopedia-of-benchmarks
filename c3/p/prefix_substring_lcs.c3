module prefix_substring_lcs;

const usz MAX_M = 32, MAX_N = 32, MAX_Q = 64;
const usz STRIDE = MAX_N + 1;
const usz MAX_INPUT = 3 + MAX_M + MAX_N + 3 * MAX_Q;

struct Query { usz a, b, c; }

fn void fenwick_add(int* tree, usz position, usz count) {
    for (usz index = position + 1; index <= count; index += index & (~index + 1)) tree[index]++;
}

fn int fenwick_prefix(int* tree, usz exclusive) {
    int total = 0;
    for (usz index = exclusive; index > 0; index -= index & (~index + 1)) total += tree[index];
    return total;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long prefix_substring_lcs(long* input, usz length, char* output, usz capacity)
    @export("prefix_substring_lcs") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_M || input[1] < 1 || input[1] > (long)MAX_N ||
        input[2] < 1 || input[2] > (long)MAX_Q) return -1;
    usz m = (usz)input[0], n = (usz)input[1], q = (usz)input[2];
    if (length != 3 + m + n + 3 * q) return -1;

    int[MAX_M] s = zeroed;
    int[MAX_N] t = zeroed;
    usz offset = 3;
    for (usz i = 0; i < m; i++) {
        if (input[offset] < 97 || input[offset] > 122) return -1;
        s[i] = (int)input[offset++];
    }
    for (usz j = 0; j < n; j++) {
        if (input[offset] < 97 || input[offset] > 122) return -1;
        t[j] = (int)input[offset++];
    }
    Query[MAX_Q] queries = zeroed;
    int[STRIDE * STRIDE] query_head = zeroed;
    int[MAX_Q] query_next = zeroed;
    for (usz index = 0; index < STRIDE * STRIDE; index++) query_head[index] = -1;
    for (usz index = 0; index < q; index++) {
        long a = input[offset++], b = input[offset++], c = input[offset++];
        if (a < 0 || a > (long)m || b < 0 || b > c || c > (long)n) return -1;
        queries[index] = {(usz)a, (usz)b, (usz)c};
        usz key = (usz)a * STRIDE + (usz)b;
        query_next[index] = query_head[key];
        query_head[key] = (int)index;
    }
    usz output_bytes = 8 * q;
    if (output == null || capacity < output_bytes) return -2;

    int[STRIDE][STRIDE] horizontal = zeroed;
    int[STRIDE][STRIDE] vertical = zeroed;
    for (usz j = 0; j <= n; j++) horizontal[0][j] = (int)j;
    for (usz i = 1; i <= m; i++) {
        for (usz j = 1; j <= n; j++) {
            int above = horizontal[i - 1][j], left = vertical[i][j - 1];
            if (s[i - 1] == t[j - 1]) {
                horizontal[i][j] = left;
                vertical[i][j] = above;
            } else {
                horizontal[i][j] = above > left ? above : left;
                vertical[i][j] = above < left ? above : left;
            }
        }
    }

    int[MAX_Q] answers = zeroed;
    for (usz a = 0; a <= m; a++) {
        int[STRIDE] value_head = zeroed;
        int[STRIDE] value_next = zeroed;
        for (usz value = 0; value <= n; value++) value_head[value] = -1;
        for (usz position = 0; position <= n; position++) {
            usz value = (usz)horizontal[a][position];
            value_next[position] = value_head[value];
            value_head[value] = (int)position;
        }
        int[STRIDE + 1] fenwick = zeroed;
        for (usz b = 0; b <= n; b++) {
            for (int position = value_head[b]; position >= 0; position = value_next[(usz)position])
                fenwick_add(&fenwick[0], (usz)position, n + 1);
            for (int qi = query_head[a * STRIDE + b]; qi >= 0; qi = query_next[(usz)qi]) {
                Query query = queries[(usz)qi];
                answers[(usz)qi] = fenwick_prefix(&fenwick[0], query.c + 1) - fenwick_prefix(&fenwick[0], query.b + 1);
            }
        }
    }
    for (usz index = 0; index < q; index++) store_i64_le(output, 8 * index, (long)answers[index]);
    return (long)output_bytes;
}
