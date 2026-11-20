/* Bounded clean-room connected/co-connected cograph cotree profile. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { CT_N = 12, CT_M = 66, CT_PARSEABLE = 135, CT_OUTPUT = 47 };
typedef uint16_t ct_mask;

static int ct_components(ct_mask mask, const ct_mask adjacency[CT_N], bool complement,
                         ct_mask components[CT_N]) {
    ct_mask remaining = mask;
    int count = 0;
    for (int root = 0; root < CT_N; ++root) {
        const ct_mask root_bit = (ct_mask)(1u << root);
        if ((remaining & root_bit) == 0) continue;
        ct_mask reached = root_bit;
        int queue[CT_N], head = 0, tail = 0;
        queue[tail++] = root;
        while (head < tail) {
            const int vertex = queue[head++];
            ct_mask neighbors = (ct_mask)(adjacency[vertex] & mask);
            if (complement)
                neighbors = (ct_mask)(mask & (ct_mask)~adjacency[vertex] &
                                      (ct_mask)~(ct_mask)(1u << vertex));
            ct_mask fresh = (ct_mask)(neighbors & (ct_mask)~reached);
            for (int next = 0; next < CT_N; ++next) {
                const ct_mask bit = (ct_mask)(1u << next);
                if (fresh & bit) {
                    fresh = (ct_mask)(fresh & (ct_mask)~bit);
                    reached = (ct_mask)(reached | bit);
                    queue[tail++] = next;
                }
            }
        }
        components[count++] = reached;
        remaining = (ct_mask)(remaining & (ct_mask)~reached);
    }
    return count;
}

static bool ct_emit(ct_mask mask, const ct_mask adjacency[CT_N],
                    uint8_t output[CT_OUTPUT], size_t *position) {
    if ((mask & (ct_mask)(mask - 1u)) == 0) {
        int vertex = 0;
        while ((mask & (ct_mask)(1u << vertex)) == 0) ++vertex;
        output[(*position)++] = 0;
        output[(*position)++] = (uint8_t)vertex;
        return true;
    }
    ct_mask parts[CT_N];
    int count = ct_components(mask, adjacency, false, parts);
    uint8_t kind = 1;
    if (count == 1) {
        count = ct_components(mask, adjacency, true, parts);
        kind = 2;
        if (count <= 1) return false;
    }
    output[(*position)++] = kind;
    output[(*position)++] = (uint8_t)count;
    for (int i = 0; i < count; ++i)
        if (!ct_emit(parts[i], adjacency, output, position)) return false;
    return true;
}

int64_t cograph_cotree_decomposition(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > CT_PARSEABLE) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > CT_N || m64 < 0 || m64 > CT_M || m64 > n64 * (n64 - 1) / 2 ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;
    ct_mask adjacency[CT_N] = {0};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n || u64 == v64) return -1;
        const int u = (int)u64, v = (int)v64;
        const ct_mask ub = (ct_mask)(1u << u), vb = (ct_mask)(1u << v);
        if (adjacency[u] & vb) return -1;
        adjacency[u] = (ct_mask)(adjacency[u] | vb);
        adjacency[v] = (ct_mask)(adjacency[v] | ub);
    }

    uint8_t staged[CT_OUTPUT] = {0};
    size_t output_length = 1;
    const ct_mask all = (ct_mask)((1u << n) - 1u);
    if (ct_emit(all, adjacency, staged, &output_length)) staged[0] = 1;
    else { staged[0] = 0; output_length = 1; }
    if (output == NULL || capacity < output_length) return -2;
    memcpy(output, staged, output_length);
    return (int64_t)output_length;
}
