#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64
#define MAX_EULER (2 * MAX_N - 1)
#define MAX_BLOCKS MAX_EULER
#define MAX_LEVELS 8
#define MAX_MICRO 4

static uint16_t shallower(uint16_t a, uint16_t b, const uint16_t *depth) {
    if (depth[a] != depth[b]) return depth[a] < depth[b] ? a : b;
    return a < b ? a : b;
}

static uint16_t range_minimum(uint16_t first, uint16_t last, size_t count,
    size_t block_size, const uint16_t *depth, const uint8_t *pattern,
    const uint8_t micro[8][MAX_MICRO][MAX_MICRO],
    const uint16_t macro[MAX_LEVELS][MAX_BLOCKS], const uint8_t *logs) {
    const size_t ba = first / block_size, bb = last / block_size;
    const size_t oa = first % block_size, ob = last % block_size;
    if (ba == bb) return (uint16_t)(ba * block_size + micro[pattern[ba]][oa][ob]);
    const size_t base_a = ba * block_size, base_b = bb * block_size;
    const size_t len_a = (count - base_a < block_size) ? count - base_a : block_size;
    uint16_t best = (uint16_t)(base_a + micro[pattern[ba]][oa][len_a - 1]);
    best = shallower(best, (uint16_t)(base_b + micro[pattern[bb]][0][ob]), depth);
    if (bb > ba + 1) {
        const size_t lo = ba + 1, hi = bb - 1, span_count = hi - lo + 1;
        const size_t level = logs[span_count], span = (size_t)1 << level;
        best = shallower(best, macro[level][lo], depth);
        best = shallower(best, macro[level][hi - span + 1], depth);
    }
    return best;
}

int64_t rmq_cartesian_tree_fcb(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 195) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_Q) return -1;
    const size_t n = (size_t)input[0], q = (size_t)input[1];
    if (length != 2 + n + 2 * q) return -1;
    int64_t value[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        value[i] = input[2 + i];
        if (value[i] < -1000 || value[i] > 1000) return -1;
    }
    const size_t query_offset = 2 + n;
    for (size_t i = 0; i < q; ++i) {
        const int64_t lo = input[query_offset + 2 * i], hi = input[query_offset + 2 * i + 1];
        if (lo < 0 || hi < lo || hi >= (int64_t)n) return -1;
    }
    if (output == NULL || capacity < q + 1) return -2;

    int left[MAX_N], right[MAX_N], parent[MAX_N], monotone[MAX_N];
    for (size_t i = 0; i < n; ++i) left[i] = right[i] = -1, parent[i] = -1;
    size_t stack_count = 0;
    for (size_t i = 0; i < n; ++i) {
        int last = -1;
        while (stack_count > 0 && value[monotone[stack_count - 1]] > value[i])
            last = monotone[--stack_count];
        if (stack_count > 0) {
            const int p = monotone[stack_count - 1];
            right[p] = (int)i; parent[i] = p;
        }
        if (last >= 0) { left[i] = last; parent[last] = (int)i; }
        monotone[stack_count++] = (int)i;
    }
    int root = -1;
    for (size_t i = 0; i < n; ++i) if (parent[i] < 0) { root = (int)i; break; }

    uint16_t euler[MAX_EULER], euler_depth[MAX_EULER], first[MAX_N];
    uint16_t node_depth[MAX_N];
    int frame_node[MAX_N]; uint8_t frame_state[MAX_N];
    size_t euler_count = 1, top = 1;
    euler[0] = (uint16_t)root; euler_depth[0] = 0; first[root] = 0; node_depth[root] = 0;
    frame_node[0] = root; frame_state[0] = 0;
    while (top > 0) {
        const size_t slot = top - 1; const int node = frame_node[slot];
        if (frame_state[slot] == 0) {
            if (left[node] >= 0) {
                const int child = left[node]; frame_state[slot] = 1;
                node_depth[child] = (uint16_t)(node_depth[node] + 1);
                first[child] = (uint16_t)euler_count; euler[euler_count] = (uint16_t)child;
                euler_depth[euler_count++] = node_depth[child];
                frame_node[top] = child; frame_state[top++] = 0;
            } else if (right[node] >= 0) {
                const int child = right[node]; frame_state[slot] = 2;
                node_depth[child] = (uint16_t)(node_depth[node] + 1);
                first[child] = (uint16_t)euler_count; euler[euler_count] = (uint16_t)child;
                euler_depth[euler_count++] = node_depth[child];
                frame_node[top] = child; frame_state[top++] = 0;
            } else --top;
        } else if (frame_state[slot] == 1) {
            euler[euler_count] = (uint16_t)node; euler_depth[euler_count++] = node_depth[node];
            if (right[node] >= 0) {
                const int child = right[node]; frame_state[slot] = 2;
                node_depth[child] = (uint16_t)(node_depth[node] + 1);
                first[child] = (uint16_t)euler_count; euler[euler_count] = (uint16_t)child;
                euler_depth[euler_count++] = node_depth[child];
                frame_node[top] = child; frame_state[top++] = 0;
            } else --top;
        } else {
            euler[euler_count] = (uint16_t)node; euler_depth[euler_count++] = node_depth[node]; --top;
        }
    }

    size_t logarithm = 0; for (size_t x = euler_count; x > 1; x >>= 1) ++logarithm;
    size_t block_size = logarithm / 2; if (block_size < 1) block_size = 1;
    const size_t block_count = (euler_count + block_size - 1) / block_size;
    uint8_t micro[8][MAX_MICRO][MAX_MICRO] = {{{0}}}, pattern[MAX_BLOCKS] = {0}, logs[MAX_BLOCKS + 1] = {0};
    uint16_t macro[MAX_LEVELS][MAX_BLOCKS] = {{0}};
    for (size_t shape = 0; shape < ((size_t)1 << (block_size - 1)); ++shape) {
        int relative[MAX_MICRO] = {0};
        for (size_t step = 0; step + 1 < block_size; ++step)
            relative[step + 1] = relative[step] + (((shape >> step) & 1) ? 1 : -1);
        for (size_t lo = 0; lo < block_size; ++lo) {
            size_t best = lo;
            for (size_t hi = lo; hi < block_size; ++hi) {
                if (relative[hi] < relative[best]) best = hi;
                micro[shape][lo][hi] = (uint8_t)best;
            }
        }
    }
    for (size_t b = 0; b < block_count; ++b) {
        const size_t base = b * block_size, end = (euler_count < base + block_size) ? euler_count : base + block_size;
        uint16_t best = (uint16_t)base;
        for (size_t at = base + 1; at < end; ++at) {
            if (euler_depth[at] > euler_depth[at - 1]) pattern[b] |= (uint8_t)(1u << (at - base - 1));
            best = shallower(best, (uint16_t)at, euler_depth);
        }
        macro[0][b] = best;
    }
    for (size_t c = 2; c <= block_count; ++c) logs[c] = (uint8_t)(logs[c / 2] + 1);
    size_t levels = 1;
    while (((size_t)1 << levels) <= block_count && levels < MAX_LEVELS) {
        const size_t half = (size_t)1 << (levels - 1), span = 2 * half;
        for (size_t b = 0; b + span <= block_count; ++b)
            macro[levels][b] = shallower(macro[levels - 1][b], macro[levels - 1][b + half], euler_depth);
        ++levels;
    }
    uint8_t answers[MAX_Q];
    for (size_t i = 0; i < q; ++i) {
        size_t lo = first[input[query_offset + 2 * i]], hi = first[input[query_offset + 2 * i + 1]];
        if (lo > hi) { size_t tmp = lo; lo = hi; hi = tmp; }
        const uint16_t at = range_minimum((uint16_t)lo, (uint16_t)hi, euler_count, block_size,
            euler_depth, pattern, micro, macro, logs);
        answers[i] = (uint8_t)euler[at];
    }
    output[0] = (uint8_t)q;
    for (size_t i = 0; i < q; ++i) output[i + 1] = answers[i];
    return (int64_t)(q + 1);
}
