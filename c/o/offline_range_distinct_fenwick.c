#include <stddef.h>
#include <stdint.h>

static void distinct_add(int *tree, size_t n, size_t position, int delta) {
    for (size_t i = position + 1; i <= n; i += i & (~i + 1)) tree[i] += delta;
}

static int distinct_prefix(const int *tree, size_t end) {
    int sum = 0;
    for (size_t i = end; i; i &= i - 1) sum += tree[i];
    return sum;
}

int64_t offline_range_distinct_fenwick(const int64_t *input, size_t length) {
    if (!input || length < 3 || length > 195) return -1;
    int64_t nr = input[0], qr = input[1];
    if (nr < 1 || nr > 64 || qr < 0 || qr > 64) return -1;
    size_t n = (size_t)nr, q = (size_t)qr;
    if (length != 2 + n + 2 * q) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2+i] < 0 || input[2+i] > 255) return -1;
    int head[65], next[64], last[256], tree[65] = {0};
    for (size_t i = 0; i < 65; ++i) head[i] = -1;
    for (size_t i = 0; i < 256; ++i) last[i] = -1;
    for (size_t i = 0; i < q; ++i) {
        int64_t left = input[2+n+2*i], right = input[3+n+2*i];
        if (left < 0 || left > right || right > nr) return -1;
        next[i] = head[right]; head[right] = (int)i;
    }
    int64_t result = 0;
    for (size_t right = 0; right <= n; ++right) {
        if (right) {
            size_t value = (size_t)input[1+right];
            if (last[value] >= 0) distinct_add(tree, n, (size_t)last[value], -1);
            distinct_add(tree, n, right-1, 1); last[value] = (int)(right-1);
        }
        for (int i = head[right]; i >= 0; i = next[i]) {
            size_t left = (size_t)input[2+n+2*(size_t)i];
            result += (int64_t)(i+1) * (distinct_prefix(tree, right) - distinct_prefix(tree, left));
        }
    }
    return result;
}
