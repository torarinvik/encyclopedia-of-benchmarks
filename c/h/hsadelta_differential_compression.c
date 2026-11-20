#include <stddef.h>
#include <stdint.h>

enum { MAX_LEN = 32, MAX_BLOCKS = 16, MAX_WORDS = 114, MAX_BYTES = 912, MAX_INPUT = 68 };
enum { INSERT = 0, COPY = 1 };

static int64_t block_hash(const int64_t *data, size_t start, size_t width) {
    int64_t value = 0;
    for (size_t i = 0; i < width; ++i) value = value * 257 + data[start + i] + 1;
    return value;
}

static int suffix_compare(const int64_t *hashes, size_t count, size_t a, size_t b) {
    while (a < count && b < count) {
        if (hashes[a] != hashes[b]) return hashes[a] < hashes[b] ? -1 : 1;
        ++a; ++b;
    }
    if (a == count && b == count) return 0;
    return a == count ? -1 : 1;
}

static int prefix_compare(const int64_t *hashes, size_t count, size_t suffix,
                          const int64_t *query, size_t qcount, size_t depth) {
    for (size_t i = 0; i < depth; ++i) {
        if (suffix + i >= count) return -1;
        if (hashes[suffix + i] != query[i]) return hashes[suffix + i] < query[i] ? -1 : 1;
    }
    (void)qcount;
    return 0;
}

static void prefix_interval(const size_t *sa, size_t count, const int64_t *hashes,
                            const int64_t *query, size_t qcount, size_t depth,
                            size_t *first, size_t *last) {
    size_t lo = 0, hi = count;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (prefix_compare(hashes, count, sa[mid], query, qcount, depth) < 0) lo = mid + 1;
        else hi = mid;
    }
    *first = lo; hi = count;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (prefix_compare(hashes, count, sa[mid], query, qcount, depth) <= 0) lo = mid + 1;
        else hi = mid;
    }
    *last = lo;
}

static size_t best_depth(const size_t *sa, size_t count, const int64_t *hashes,
                         const int64_t *query, size_t qcount) {
    size_t lo = 0, hi = (count < qcount ? count : qcount) + 1;
    while (lo + 1 < hi) {
        size_t mid = lo + (hi - lo) / 2, first, last;
        prefix_interval(sa, count, hashes, query, qcount, mid, &first, &last);
        if (first < last) lo = mid; else hi = mid;
    }
    return lo;
}

static size_t extend_match(const int64_t *ref, size_t m, const int64_t *ver, size_t n,
                           size_t source, size_t target, size_t floor, size_t *out_source,
                           size_t *out_target) {
    size_t length = 0;
    while (source + length < m && target + length < n && ref[source + length] == ver[target + length]) ++length;
    while (source > 0 && target > floor && ref[source - 1] == ver[target - 1]) {
        --source; --target; ++length;
    }
    *out_source = source; *out_target = target;
    return length;
}

static int find_at(const int64_t *ref, size_t m, const int64_t *ver, size_t n, size_t p,
                   const size_t *sa, size_t block_count, const int64_t *ref_hashes,
                   size_t target, size_t floor, size_t *best_source, size_t *best_target,
                   size_t *best_length) {
    size_t qcount = (n - target) / p;
    if (qcount == 0 || block_count == 0) return 0;
    int64_t query[MAX_BLOCKS];
    for (size_t i = 0; i < qcount; ++i) query[i] = block_hash(ver, target + i * p, p);
    size_t depth = best_depth(sa, block_count, ref_hashes, query, qcount);
    if (depth == 0) return 0;
    size_t checked = depth > 1 ? depth - 1 : 1, first, last;
    prefix_interval(sa, block_count, ref_hashes, query, qcount, checked, &first, &last);
    int found = 0;
    for (size_t rank = first; rank < last; ++rank) {
        size_t source = sa[rank] * p, start_source, start_target;
        if (source + p > m) continue;
        size_t length = extend_match(ref, m, ver, n, source, target, floor, &start_source, &start_target);
        if (length < p) continue;
        if (!found || length > *best_length ||
            (length == *best_length && (start_target < *best_target ||
             (start_target == *best_target && start_source < *best_source)))) {
            found = 1; *best_source = start_source; *best_target = start_target; *best_length = length;
        }
    }
    return found;
}

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

int64_t hsadelta_differential_compression(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t mv = input[0], nv = input[1], pv = input[2];
    if (mv < 0 || mv > MAX_LEN || nv < 0 || nv > MAX_LEN || pv < 2 || pv > 4) return -1;
    size_t m = (size_t)mv, n = (size_t)nv, p = (size_t)pv;
    if (length != 3 + m + n) return -1;
    const int64_t *ref = input + 3, *ver = input + 3 + m;
    for (size_t i = 0; i < m + n; ++i) if (input[3 + i] < 0 || input[3 + i] > 255) return -1;

    int64_t hashes[MAX_BLOCKS]; size_t sa[MAX_BLOCKS];
    size_t block_count = m >= p ? (m - p) / p + 1 : 0;
    for (size_t i = 0; i < block_count; ++i) { hashes[i] = block_hash(ref, i * p, p); sa[i] = i; }
    for (size_t i = 1; i < block_count; ++i) {
        size_t value = sa[i], j = i;
        while (j > 0 && (suffix_compare(hashes, block_count, value, sa[j - 1]) < 0 ||
               (suffix_compare(hashes, block_count, value, sa[j - 1]) == 0 && value < sa[j - 1]))) {
            sa[j] = sa[j - 1]; --j;
        }
        sa[j] = value;
    }

    int64_t tokens[MAX_WORDS]; size_t words = 0, cursor = 0, consumed = 0;
    while (cursor + p <= n) {
        int found = 0; size_t bs = 0, bt = 0, bl = 0;
        size_t scan_end = cursor + p - 1 < n - p ? cursor + p - 1 : n - p;
        for (size_t target = cursor; target <= scan_end; ++target) {
            size_t cs = 0, ct = 0, cl = 0;
            if (find_at(ref, m, ver, n, p, sa, block_count, hashes, target, consumed, &cs, &ct, &cl) &&
                (!found || cl > bl || (cl == bl && (ct < bt || (ct == bt && cs < bs)))) ) {
                found = 1; bs = cs; bt = ct; bl = cl;
            }
        }
        if (!found) { ++cursor; continue; }
        if (bt > consumed) { tokens[words++] = INSERT; tokens[words++] = (int64_t)(bt - consumed);
            for (size_t i = consumed; i < bt; ++i) tokens[words++] = ver[i]; }
        tokens[words++] = COPY; tokens[words++] = (int64_t)bs; tokens[words++] = (int64_t)bl;
        consumed = bt + bl; cursor = consumed;
    }
    if (consumed < n) { tokens[words++] = INSERT; tokens[words++] = (int64_t)(n - consumed);
        for (size_t i = consumed; i < n; ++i) tokens[words++] = ver[i]; }
    size_t required = words * 8;
    if (required != 0 && (output == NULL || capacity < required)) return -2;
    for (size_t i = 0; i < words; ++i) put_i64(output, 8 * i, tokens[i]);
    return (int64_t)required;
}
