#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_TAXA = 8, MAX_CHARACTERS = 8, MAX_LITERALS = 48, MAX_INPUT = 67 };

static void add_clause(uint8_t graph[MAX_LITERALS][MAX_LITERALS],
                       uint8_t reverse[MAX_LITERALS][MAX_LITERALS],
                       int left, int right) {
    int from_left = left ^ 1;
    int from_right = right ^ 1;
    graph[from_left][right] = 1;
    reverse[right][from_left] = 1;
    graph[from_right][left] = 1;
    reverse[left][from_right] = 1;
}

static void finish_dfs(int vertex, int count,
                       const uint8_t graph[MAX_LITERALS][MAX_LITERALS],
                       bool seen[MAX_LITERALS], int order[MAX_LITERALS],
                       int *order_count) {
    seen[vertex] = true;
    for (int next = 0; next < count; ++next)
        if (graph[vertex][next] && !seen[next])
            finish_dfs(next, count, graph, seen, order, order_count);
    order[(*order_count)++] = vertex;
}

static void component_dfs(int vertex, int count,
                          const uint8_t reverse[MAX_LITERALS][MAX_LITERALS],
                          int component[MAX_LITERALS], int label) {
    component[vertex] = label;
    for (int next = 0; next < count; ++next)
        if (reverse[vertex][next] && component[next] < 0)
            component_dfs(next, count, reverse, component, label);
}

int64_t perfect_phylogeny_three_state_2sat(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t taxa_raw = input[0], character_raw = input[1];
    if (taxa_raw < 1 || taxa_raw > MAX_TAXA || character_raw < 0 || character_raw > MAX_CHARACTERS)
        return -1;
    int taxa = (int)taxa_raw, characters = (int)character_raw;
    if (length != 2u + (size_t)taxa * (size_t)characters) return -1;

    uint16_t state_mask[MAX_CHARACTERS][3] = {{0}};
    for (int taxon = 0; taxon < taxa; ++taxon) {
        for (int character = 0; character < characters; ++character) {
            int64_t state = input[2 + taxon * characters + character];
            if (state < 0 || state > 2) return -1;
            state_mask[character][state] |= (uint16_t)(1u << taxon);
        }
    }

    uint8_t graph[MAX_LITERALS][MAX_LITERALS] = {{0}};
    uint8_t reverse[MAX_LITERALS][MAX_LITERALS] = {{0}};
    for (int character = 0; character < characters; ++character) {
        int v0 = 3 * character, v1 = v0 + 1, v2 = v0 + 2;
        add_clause(graph, reverse, 2 * v0, 2 * v1);
        add_clause(graph, reverse, 2 * v0, 2 * v2);
        add_clause(graph, reverse, 2 * v1, 2 * v2);
        int present = 0, missing = -1;
        for (int state = 0; state < 3; ++state) {
            if (state_mask[character][state]) ++present;
            else missing = state;
        }
        if (present == 2) {
            int absent_literal = 2 * (3 * character + missing) + 1;
            add_clause(graph, reverse, absent_literal, absent_literal);
        }
    }
    uint16_t universe = (uint16_t)((1u << taxa) - 1u);
    for (int left_character = 0; left_character < characters; ++left_character) {
        for (int right_character = left_character + 1; right_character < characters; ++right_character) {
            for (int left_state = 0; left_state < 3; ++left_state) {
                uint16_t left = state_mask[left_character][left_state];
                for (int right_state = 0; right_state < 3; ++right_state) {
                    uint16_t right = state_mask[right_character][right_state];
                    uint16_t both = left & right;
                    uint16_t left_only = left & (uint16_t)(universe & (uint16_t)~right);
                    uint16_t right_only = right & (uint16_t)(universe & (uint16_t)~left);
                    uint16_t neither = (uint16_t)(universe & (uint16_t)~(left | right));
                    if (both && left_only && right_only && neither) {
                        int left_variable = 3 * left_character + left_state;
                        int right_variable = 3 * right_character + right_state;
                        add_clause(graph, reverse, 2 * left_variable + 1,
                                   2 * right_variable + 1);
                    }
                }
            }
        }
    }

    int literal_count = 6 * characters;
    bool seen[MAX_LITERALS] = {false};
    int order[MAX_LITERALS], order_count = 0;
    for (int literal = 0; literal < literal_count; ++literal)
        if (!seen[literal]) finish_dfs(literal, literal_count, graph, seen, order, &order_count);
    int component[MAX_LITERALS];
    for (int literal = 0; literal < literal_count; ++literal) component[literal] = -1;
    int label = 0;
    while (order_count > 0) {
        int literal = order[--order_count];
        if (component[literal] < 0) component_dfs(literal, literal_count, reverse, component, label++);
    }
    for (int variable = 0; variable < 3 * characters; ++variable)
        if (component[2 * variable] == component[2 * variable + 1]) return 0;
    return 1;
}
