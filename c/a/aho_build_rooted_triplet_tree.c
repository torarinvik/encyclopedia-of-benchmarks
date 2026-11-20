#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_TAXA 7
#define MAX_TRIPLETS 105
#define MAX_TREE_NODES 13
#define MAX_PARSEABLE_WORDS 318

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int build_aho(const int32_t triples[MAX_TRIPLETS][3], size_t q, int n,
                     int kind[MAX_TREE_NODES], int value[MAX_TREE_NODES],
                     size_t *node_count)
{
    uint8_t tasks[MAX_TREE_NODES];
    size_t top = 1;
    tasks[0] = (uint8_t)((1u << n) - 1u);
    *node_count = 0;
    while (top > 0) {
        const uint8_t mask = tasks[--top];
        if ((mask & (uint8_t)(mask - 1u)) == 0) {
            int label = 0;
            while ((mask & (uint8_t)(1u << label)) == 0) ++label;
            kind[*node_count] = 1;
            value[*node_count] = label;
            ++*node_count;
            continue;
        }

        uint8_t adjacent[MAX_TAXA][MAX_TAXA] = {{0}};
        for (size_t i = 0; i < q; ++i) {
            const int a = triples[i][0], b = triples[i][1], c = triples[i][2];
            const uint8_t bits = (uint8_t)((1u << a) | (1u << b) | (1u << c));
            if ((mask & bits) == bits) adjacent[a][b] = adjacent[b][a] = 1;
        }

        uint8_t seen = 0, components[MAX_TAXA];
        size_t component_count = 0;
        for (int start = 0; start < n; ++start) {
            const uint8_t start_bit = (uint8_t)(1u << start);
            if ((mask & start_bit) == 0 || (seen & start_bit) != 0) continue;
            int queue[MAX_TAXA];
            size_t head = 0, tail = 0;
            uint8_t component = 0;
            queue[tail++] = start;
            seen |= start_bit;
            while (head < tail) {
                const int current = queue[head++];
                component |= (uint8_t)(1u << current);
                for (int other = 0; other < n; ++other) {
                    const uint8_t other_bit = (uint8_t)(1u << other);
                    if (adjacent[current][other] && (mask & other_bit) != 0
                        && (seen & other_bit) == 0) {
                        seen |= other_bit;
                        queue[tail++] = other;
                    }
                }
            }
            components[component_count++] = component;
        }
        if (component_count == 1) return 0;
        kind[*node_count] = 0;
        value[*node_count] = (int)component_count;
        ++*node_count;
        for (size_t i = component_count; i > 0; --i)
            tasks[top++] = components[i - 1];
    }
    return 1;
}

int64_t aho_build_rooted_triplet_tree(const int64_t *input, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_WORDS) return -1;
    const int64_t n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > MAX_TAXA || q64 < 0) return -1;
    const int n = (int)n64;
    const size_t q_limit = (size_t)(n * (n - 1) * (n - 2) / 2);
    if ((uint64_t)q64 > q_limit) return -1;
    const size_t q = (size_t)q64;
    if (length != 2 + 3 * q) return -1;

    int32_t triples[MAX_TRIPLETS][3];
    for (size_t i = 0; i < q; ++i) {
        const int64_t a64 = input[2 + 3 * i];
        const int64_t b64 = input[3 + 3 * i];
        const int64_t c64 = input[4 + 3 * i];
        if (a64 < 0 || a64 >= n || b64 < 0 || b64 >= n || c64 < 0 || c64 >= n
            || a64 == b64 || a64 == c64 || b64 == c64) return -1;
        int a = (int)a64, b = (int)b64;
        if (a > b) { const int temporary = a; a = b; b = temporary; }
        for (size_t j = 0; j < i; ++j)
            if (triples[j][0] == a && triples[j][1] == b && triples[j][2] == (int)c64) return -1;
        triples[i][0] = a;
        triples[i][1] = b;
        triples[i][2] = (int)c64;
    }

    int kind[MAX_TREE_NODES], value[MAX_TREE_NODES];
    size_t node_count = 0;
    const int compatible = build_aho(triples, q, n, kind, value, &node_count);
    int64_t words[1 + MAX_TREE_NODES];
    size_t word_count;
    if (!compatible) {
        words[0] = 0;
        word_count = 1;
    } else {
        words[0] = (int64_t)node_count;
        for (size_t i = 0; i < node_count; ++i)
            words[i + 1] = kind[i] ? -(int64_t)(value[i] + 1) : (int64_t)value[i];
        word_count = node_count + 1;
    }
    const size_t output_size = word_count * 8;
    if (output == NULL || output_capacity < output_size) return -2;
    for (size_t i = 0; i < word_count; ++i) store_i64_le(output, 8 * i, words[i]);
    return (int64_t)output_size;
}
