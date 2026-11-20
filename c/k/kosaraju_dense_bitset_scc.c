#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 256
#define MAX_WORDS 4
#define MAX_CELLS (MAX_VERTICES * MAX_WORDS)
#define MAX_VALID_INPUT_LENGTH (1 + MAX_CELLS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)

static unsigned lowest_bit_index(uint64_t bits)
{
    unsigned index = 0;
    while ((bits & UINT64_C(1)) == 0) { bits >>= 1; ++index; }
    return index;
}

static void write_u16_le(uint8_t *output, size_t position, uint16_t value)
{
    output[position] = (uint8_t)(value & UINT16_C(0xff));
    output[position + 1] = (uint8_t)(value >> 8);
}

int64_t kosaraju_dense_bitset_scc(const int64_t *input, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES) return -1;
    const size_t n = (size_t)input[0];
    const size_t words = (n + 63) / 64;
    if (length != 1 + n * words) return -1;

    uint64_t adjacency[MAX_CELLS] = {0};
    uint64_t transpose[MAX_CELLS] = {0};
    for (size_t i = 0; i < n * words; ++i) adjacency[i] = (uint64_t)input[1 + i];
    if ((n & 63u) != 0) {
        const uint64_t valid = (UINT64_C(1) << (n & 63u)) - 1;
        for (size_t vertex = 0; vertex < n; ++vertex)
            if ((adjacency[vertex * words + words - 1] & ~valid) != 0) return -1;
    }

    for (size_t source = 0; source < n; ++source) {
        for (size_t word = 0; word < words; ++word) {
            uint64_t bits = adjacency[source * words + word];
            while (bits != 0) {
                const unsigned bit = lowest_bit_index(bits);
                const size_t target = word * 64 + bit;
                transpose[target * words + source / 64] |= UINT64_C(1) << (source & 63u);
                bits &= bits - 1;
            }
        }
    }

    uint64_t unvisited[MAX_WORDS] = {0};
    for (size_t word = 0; word < words; ++word) unvisited[word] = UINT64_MAX;
    if ((n & 63u) != 0) unvisited[words - 1] = (UINT64_C(1) << (n & 63u)) - 1;
    uint16_t stack[MAX_VERTICES], next_word[MAX_VERTICES], order[MAX_VERTICES];
    size_t order_length = 0;
    for (size_t root = 0; root < n; ++root) {
        const size_t root_word = root / 64, root_bit = root & 63u;
        if (((unvisited[root_word] >> root_bit) & 1u) == 0) continue;
        unvisited[root_word] &= ~(UINT64_C(1) << root_bit);
        size_t stack_length = 1;
        stack[0] = (uint16_t)root;
        next_word[0] = 0;
        while (stack_length != 0) {
            const size_t depth = stack_length - 1;
            const size_t vertex = stack[depth];
            bool pushed = false;
            while (next_word[depth] < words) {
                const size_t word = next_word[depth];
                const uint64_t candidates = adjacency[vertex * words + word] & unvisited[word];
                if (candidates != 0) {
                    const unsigned bit = lowest_bit_index(candidates);
                    const size_t neighbor = word * 64 + bit;
                    unvisited[word] &= ~(UINT64_C(1) << bit);
                    stack[stack_length] = (uint16_t)neighbor;
                    next_word[stack_length] = 0;
                    ++stack_length;
                    pushed = true;
                    break;
                }
                ++next_word[depth];
            }
            if (!pushed && next_word[depth] == words) {
                order[order_length++] = (uint16_t)vertex;
                --stack_length;
            }
        }
    }

    for (size_t word = 0; word < words; ++word) unvisited[word] = UINT64_MAX;
    if ((n & 63u) != 0) unvisited[words - 1] = (UINT64_C(1) << (n & 63u)) - 1;
    uint16_t raw_component[MAX_VERTICES];
    uint16_t component_count = 0;
    while (order_length != 0) {
        const size_t root = order[--order_length];
        const size_t root_word = root / 64, root_bit = root & 63u;
        if (((unvisited[root_word] >> root_bit) & 1u) == 0) continue;
        unvisited[root_word] &= ~(UINT64_C(1) << root_bit);
        size_t stack_length = 1;
        stack[0] = (uint16_t)root;
        raw_component[root] = component_count;
        while (stack_length != 0) {
            const size_t vertex = stack[--stack_length];
            for (size_t word = 0; word < words; ++word) {
                uint64_t candidates = transpose[vertex * words + word] & unvisited[word];
                while (candidates != 0) {
                    const unsigned bit = lowest_bit_index(candidates);
                    const size_t neighbor = word * 64 + bit;
                    const uint64_t selected = UINT64_C(1) << bit;
                    unvisited[word] &= ~selected;
                    candidates &= ~selected;
                    raw_component[neighbor] = component_count;
                    stack[stack_length++] = (uint16_t)neighbor;
                }
            }
        }
        ++component_count;
    }

    uint16_t remap[MAX_VERTICES];
    for (size_t component = 0; component < MAX_VERTICES; ++component) remap[component] = UINT16_MAX;
    uint16_t canonical_count = 0;
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const uint16_t raw = raw_component[vertex];
        if (remap[raw] == UINT16_MAX) remap[raw] = canonical_count++;
    }
    const size_t output_length = 2 + 2 * n;
    if (output == NULL || output_capacity < output_length) return -2;
    write_u16_le(output, 0, canonical_count);
    for (size_t vertex = 0; vertex < n; ++vertex)
        write_u16_le(output, 2 + 2 * vertex, remap[raw_component[vertex]]);
    return (int64_t)output_length;
}
