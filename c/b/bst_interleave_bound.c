#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 8
#define MAX_ACCESSES 16
#define MAX_INPUT 36

static void store_i64_le(uint8_t *output, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t bst_interleave_bound(const int64_t *input, size_t length,
                             uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0], root_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_NODES || root_raw < 0 || root_raw >= n_raw) return -1;
    const int n = (int)n_raw, root = (int)root_raw;
    int left[MAX_NODES], right[MAX_NODES], parent[MAX_NODES], parent_count[MAX_NODES] = {0};
    size_t position = 2;
    for (int node = 0; node < n; ++node) {
        if (position + 2 > length) return -1;
        const int64_t l = input[position++], r = input[position++];
        if (l < -1 || l >= n || r < -1 || r >= n || l == node || r == node
            || (l >= 0 && l == r)) return -1;
        left[node] = (int)l; right[node] = (int)r; parent[node] = -1;
        if (l >= 0) { ++parent_count[l]; parent[l] = node; }
        if (r >= 0) { ++parent_count[r]; parent[r] = node; }
    }
    if (parent_count[root] != 0) return -1;
    for (int node = 0; node < n; ++node) if (node != root && parent_count[node] != 1) return -1;
    if (position >= length) return -1;
    const int64_t m_raw = input[position++];
    if (m_raw < 0 || m_raw > MAX_ACCESSES || length != position + (size_t)m_raw) return -1;
    const int m = (int)m_raw;
    int accesses[MAX_ACCESSES];
    for (int i = 0; i < m; ++i) {
        const int64_t key = input[position++];
        if (key < 0 || key >= n) return -1;
        accesses[i] = (int)key;
    }

    int stack_node[MAX_NODES], stack_low[MAX_NODES], stack_high[MAX_NODES];
    int stack_size = 1, visited[MAX_NODES] = {0}, visited_count = 0;
    stack_node[0] = root; stack_low[0] = -1; stack_high[0] = n;
    while (stack_size > 0) {
        --stack_size;
        const int node = stack_node[stack_size];
        const int low = stack_low[stack_size], high = stack_high[stack_size];
        if (visited[node] || node <= low || node >= high) return -1;
        visited[node] = 1; ++visited_count;
        if (left[node] >= 0) {
            stack_node[stack_size] = left[node]; stack_low[stack_size] = low; stack_high[stack_size] = node;
            ++stack_size;
        }
        if (right[node] >= 0) {
            stack_node[stack_size] = right[node]; stack_low[stack_size] = node; stack_high[stack_size] = high;
            ++stack_size;
        }
    }
    if (visited_count != n) return -1;

    int64_t bound = 0;
    for (int pivot = 0; pivot < n; ++pivot) {
        int previous = -1;
        for (int i = 0; i < m; ++i) {
            int ancestor = accesses[i];
            while (ancestor >= 0 && ancestor != pivot) ancestor = parent[ancestor];
            if (ancestor == pivot) {
                const int side = accesses[i] <= pivot ? 0 : 1;
                if (previous >= 0 && side != previous) ++bound;
                previous = side;
            }
        }
    }
    if (output == NULL || capacity < 8) return -2;
    uint8_t staged[8];
    store_i64_le(staged, bound);
    for (int byte = 0; byte < 8; ++byte) output[byte] = staged[byte];
    return 8;
}
