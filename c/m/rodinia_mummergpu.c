/* Clean-room bounded MUMmerGPU maximal exact-match query; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

#define MM_MAX_REF 32
#define MM_MAX_QUERY 32
#define MM_ALPHABET 5
#define MM_MAX_NODES (1 + MM_MAX_REF * (MM_MAX_REF + 3) / 2)
#define MM_MAX_INPUT (3 + MM_MAX_REF + MM_MAX_QUERY)
#define MM_MAX_MATCHES (MM_MAX_REF * MM_MAX_QUERY)

static int mm_child_index(int node, int symbol) { return node * MM_ALPHABET + symbol; }

static int mm_suffix_less(const int64_t *reference, int ref_len, int left, int right) {
    int a = left, b = right;
    while (a < ref_len && b < ref_len && reference[a] == reference[b]) { ++a; ++b; }
    if (a == ref_len && b == ref_len) return 0;
    if (a == ref_len) return 0; /* End marker 4 sorts after A/C/G/T. */
    if (b == ref_len) return 1;
    return reference[a] < reference[b];
}

static void mm_put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t rodinia_mummergpu(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MM_MAX_INPUT) return -1;
    const int64_t ref_len64 = input[0], query_len64 = input[1], min_len64 = input[2];
    if (ref_len64 < 1 || ref_len64 > MM_MAX_REF || query_len64 < 1 || query_len64 > MM_MAX_QUERY ||
        min_len64 < 1 || min_len64 > MM_MAX_QUERY) return -1;
    const int ref_len = (int)ref_len64, query_len = (int)query_len64, min_len = (int)min_len64;
    if (length != (size_t)(3 + ref_len + query_len)) return -1;
    int64_t reference[MM_MAX_REF], query[MM_MAX_QUERY];
    for (int i = 0; i < ref_len; ++i) {
        const int64_t code = input[3 + i];
        if (code < 0 || code > 3) return -1;
        reference[i] = code;
    }
    for (int i = 0; i < query_len; ++i) {
        const int64_t code = input[3 + ref_len + i];
        if (code < 0 || code > 3) return -1;
        query[i] = code;
    }

    int children[MM_MAX_NODES * MM_ALPHABET];
    int path_node[MM_MAX_REF * (MM_MAX_REF + 1)];
    int suffix_order[MM_MAX_REF];
    for (int i = 0; i < MM_MAX_NODES * MM_ALPHABET; ++i) children[i] = -1;
    for (int i = 0; i < MM_MAX_REF * (MM_MAX_REF + 1); ++i) path_node[i] = -1;
    int node_count = 1;
    for (int start = 0; start < ref_len; ++start) {
        int node = 0;
        path_node[start * (MM_MAX_REF + 1)] = 0;
        int depth = 0;
        for (int pos = start; pos < ref_len; ++pos) {
            const int symbol = (int)reference[pos];
            int slot = mm_child_index(node, symbol);
            if (children[slot] < 0) {
                const int fresh = node_count++;
                children[slot] = fresh;
                for (int s = 0; s < MM_ALPHABET; ++s) children[mm_child_index(fresh, s)] = -1;
            }
            node = children[slot];
            ++depth;
            path_node[start * (MM_MAX_REF + 1) + depth] = node;
        }
        const int terminal_slot = mm_child_index(node, 4);
        if (children[terminal_slot] < 0) {
            const int fresh = node_count++;
            children[terminal_slot] = fresh;
            for (int s = 0; s < MM_ALPHABET; ++s) children[mm_child_index(fresh, s)] = -1;
        }
    }

    for (int i = 0; i < ref_len; ++i) suffix_order[i] = i;
    for (int i = 1; i < ref_len; ++i) {
        const int key = suffix_order[i];
        int j = i;
        while (j > 0 && mm_suffix_less(reference, ref_len, key, suffix_order[j - 1])) {
            suffix_order[j] = suffix_order[j - 1];
            --j;
        }
        suffix_order[j] = key;
    }

    int64_t records[MM_MAX_MATCHES * 3];
    size_t match_count = 0;
    for (int qstart = 0; qstart < query_len; ++qstart) {
        int candidate[MM_MAX_REF];
        for (int r = 0; r < ref_len; ++r) candidate[r] = -1;
        int node = 0, depth = 0;
        for (;;) {
            const int query_has_next = qstart + depth < query_len;
            for (int rstart = 0; rstart < ref_len; ++rstart) {
                if (path_node[rstart * (MM_MAX_REF + 1) + depth] != node) continue;
                const int suffix_ends = rstart + depth == ref_len;
                if (suffix_ends || !query_has_next || reference[rstart + depth] != query[qstart + depth])
                    candidate[rstart] = depth;
            }
            if (!query_has_next) break;
            const int slot = mm_child_index(node, (int)query[qstart + depth]);
            if (children[slot] < 0) break;
            node = children[slot];
            ++depth;
        }
        for (int order = 0; order < ref_len; ++order) {
            const int rstart = suffix_order[order];
            const int match_len = candidate[rstart];
            if (match_len < min_len) continue;
            if (qstart > 0 && rstart > 0 && query[qstart - 1] == reference[rstart - 1]) continue;
            records[3 * match_count] = (int64_t)rstart + 1;
            records[3 * match_count + 1] = (int64_t)qstart + 1;
            records[3 * match_count + 2] = match_len;
            ++match_count;
        }
    }
    const size_t output_bytes = match_count * 24;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < 3 * match_count; ++i) mm_put_i64(output, i * 8, records[i]);
    return (int64_t)output_bytes;
}
