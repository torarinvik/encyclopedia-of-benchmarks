#include <stddef.h>
#include <stdint.h>

#define MAX_LEAVES 8
#define MAX_EDGES 13
#define MAX_INPUT 27

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static size_t bit_count(uint64_t value, size_t n)
{
    size_t count = 0;
    for (size_t bit = 0; bit < n; ++bit) count += (size_t)((value >> bit) & 1U);
    return count;
}

static int valid_tree(const int64_t *input, size_t offset, size_t n, size_t edges)
{
    uint64_t masks[MAX_EDGES] = {0};
    uint64_t internal[MAX_EDGES] = {0};
    size_t internal_count = 0;
    uint64_t universe = ((uint64_t)1 << n) - 1;
    for (size_t edge = 0; edge < edges; ++edge) {
        int64_t raw = input[offset + edge];
        if (raw <= 0 || (uint64_t)raw >= universe || (raw & 1) != 0) return 0;
        masks[edge] = (uint64_t)raw;
        for (size_t earlier = 0; earlier < edge; ++earlier) if (masks[earlier] == masks[edge]) return 0;
        size_t size = bit_count(masks[edge], n);
        if (size == 1 || size == n - 1) {
            if (size == n - 1 && masks[edge] != (universe ^ 1U)) return 0;
        } else if (size >= 2 && size <= n - 2) {
            internal[internal_count++] = masks[edge];
        } else {
            return 0;
        }
    }
    if (internal_count != n - 3) return 0;
    for (size_t leaf = 1; leaf < n; ++leaf) {
        uint64_t pendant = (uint64_t)1 << leaf;
        size_t found = 0;
        for (size_t edge = 0; edge < edges; ++edge) found += (size_t)(masks[edge] == pendant);
        if (found != 1) return 0;
    }
    size_t root_pendant = 0;
    for (size_t edge = 0; edge < edges; ++edge) root_pendant += (size_t)(masks[edge] == (universe ^ 1U));
    if (root_pendant != 1) return 0;
    for (size_t i = 0; i < internal_count; ++i) {
        for (size_t j = i + 1; j < internal_count; ++j) {
            uint64_t intersection = internal[i] & internal[j];
            if (intersection != 0 && intersection != internal[i] && intersection != internal[j]) return 0;
        }
    }
    return 1;
}

int64_t non_shared_edges(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 7 || length > MAX_INPUT) return -1;
    int64_t leaf_value = input[0];
    if (leaf_value < 3 || leaf_value > MAX_LEAVES) return -1;
    size_t leaves = (size_t)leaf_value;
    size_t edges = 2 * leaves - 3;
    if (length != 1 + 2 * edges) return -1;
    size_t second = 1 + edges;
    if (!valid_tree(input, 1, leaves, edges) || !valid_tree(input, second, leaves, edges)) return -1;
    int64_t shared = 0;
    for (size_t left = 0; left < edges; ++left) {
        for (size_t right = 0; right < edges; ++right) {
            if (input[1 + left] == input[second + right]) { ++shared; break; }
        }
    }
    if (output == NULL || capacity < 8) return -2;
    uint8_t staged[8] = {0};
    store_i64_le(staged, 0, (int64_t)edges - shared);
    for (size_t byte = 0; byte < 8; ++byte) output[byte] = staged[byte];
    return 8;
}
