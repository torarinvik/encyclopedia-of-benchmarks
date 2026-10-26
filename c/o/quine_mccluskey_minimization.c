/* Exact bounded Quine-McCluskey prime-implicant and cover search. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VARIABLES 3
#define MAX_MINTERMS 8
#define MAX_CUBES 27
#define MAX_STATES 256
#define MAX_INPUT_LENGTH 9
#define MAX_OUTPUT_BYTES 136
#define INF 99

static int valid_cube(unsigned care, unsigned value, const int64_t *status,
                      size_t size, unsigned *covered_on)
{
    unsigned cover = 0;
    for (size_t minterm = 0; minterm < size; ++minterm) {
        if (((unsigned)minterm & care) == value) {
            if (status[minterm] == 0) return 0;
            if (status[minterm] == 1) cover |= 1u << minterm;
        }
    }
    if (covered_on != NULL) *covered_on = cover;
    return cover != 0;
}

static int lexicographically_better(uint32_t candidate, uint32_t incumbent,
                                    size_t prime_count)
{
    for (size_t index = 0; index < prime_count; ++index) {
        const uint32_t bit = 1u << index;
        const int left = (candidate & bit) != 0;
        const int right = (incumbent & bit) != 0;
        if (left != right) return left;
    }
    return 0;
}

int64_t quine_mccluskey_minimization(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VARIABLES) return -1;
    const size_t n = (size_t)input[0];
    const size_t size = 1u << n;
    if (length != 1 + size) return -1;
    for (size_t minterm = 0; minterm < size; ++minterm) {
        if (input[1 + minterm] < 0 || input[1 + minterm] > 2) return -1;
    }

    unsigned care[MAX_CUBES], value[MAX_CUBES], cover[MAX_CUBES], literals[MAX_CUBES];
    size_t prime_count = 0;
    const unsigned full = (unsigned)size - 1;
    for (unsigned cube_care = 0; cube_care <= full; ++cube_care) {
        for (unsigned cube_value = 0; cube_value <= full; ++cube_value) {
            if ((cube_value & ~cube_care) != 0) continue;
            unsigned on_cover = 0;
            if (!valid_cube(cube_care, cube_value, input + 1, size, &on_cover)) continue;
            int prime = 1;
            for (size_t variable = 0; variable < n; ++variable) {
                const unsigned bit = 1u << variable;
                if ((cube_care & bit) != 0 &&
                    valid_cube(cube_care ^ bit, cube_value & ~bit, input + 1, size, NULL)) {
                    prime = 0;
                    break;
                }
            }
            if (prime) {
                care[prime_count] = cube_care;
                value[prime_count] = cube_value;
                cover[prime_count] = on_cover;
                unsigned bits = cube_care;
                unsigned count = 0;
                while (bits != 0) { count += bits & 1u; bits >>= 1; }
                literals[prime_count] = count;
                ++prime_count;
            }
        }
    }

    unsigned on_mask = 0;
    for (size_t minterm = 0; minterm < size; ++minterm) {
        if (input[1 + minterm] == 1) on_mask |= 1u << minterm;
    }
    const size_t state_count = 1u << size;
    unsigned term_cost[MAX_STATES], literal_cost[MAX_STATES];
    uint32_t selected[MAX_STATES];
    for (size_t state = 0; state < state_count; ++state) {
        term_cost[state] = INF;
        literal_cost[state] = INF;
        selected[state] = 0;
    }
    term_cost[0] = 0;
    literal_cost[0] = 0;
    for (size_t index = 0; index < prime_count; ++index) {
        const uint32_t prime_bit = 1u << index;
        for (size_t state = state_count; state-- > 0;) {
            if (term_cost[state] == INF) continue;
            const size_t destination = state | cover[index];
            if (destination == state) continue;
            const unsigned new_terms = term_cost[state] + 1;
            const unsigned new_literals = literal_cost[state] + literals[index];
            const uint32_t new_selected = selected[state] | prime_bit;
            int better = new_terms < term_cost[destination];
            if (new_terms == term_cost[destination]) {
                better = new_literals < literal_cost[destination];
                if (new_literals == literal_cost[destination]) {
                    better = lexicographically_better(new_selected, selected[destination], prime_count);
                }
            }
            if (better) {
                term_cost[destination] = new_terms;
                literal_cost[destination] = new_literals;
                selected[destination] = new_selected;
            }
        }
    }
    const unsigned chosen = selected[on_mask];
    size_t term_count = 0;
    for (size_t index = 0; index < prime_count; ++index) {
        if ((chosen & (1u << index)) != 0) ++term_count;
    }
    const size_t output_bytes = 8 * (1 + 2 * term_count);
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t words[1 + 2 * MAX_MINTERMS];
    words[0] = (int64_t)term_count;
    size_t cursor = 1;
    for (size_t index = 0; index < prime_count; ++index) {
        if ((chosen & (1u << index)) != 0) {
            words[cursor++] = (int64_t)care[index];
            words[cursor++] = (int64_t)value[index];
        }
    }
    for (size_t word = 0; word < cursor; ++word) {
        uint64_t bits = (uint64_t)words[word];
        for (size_t byte = 0; byte < 8; ++byte) {
            output[word * 8 + byte] = (uint8_t)(bits & 255);
            bits >>= 8;
        }
    }
    return (int64_t)output_bytes;
}
