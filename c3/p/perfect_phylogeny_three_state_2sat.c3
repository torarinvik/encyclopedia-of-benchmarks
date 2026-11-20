module perfect_phylogeny_three_state_2sat;

const int MAX_TAXA = 8, MAX_CHARACTERS = 8, MAX_LITERALS = 48;
const usz MAX_INPUT = 67;

fn void add_clause(bool[MAX_LITERALS][MAX_LITERALS]* graph,
                   bool[MAX_LITERALS][MAX_LITERALS]* reverse,
                   int left, int right) {
    int from_left = left ^ 1, from_right = right ^ 1;
    (*graph)[from_left][right] = true; (*reverse)[right][from_left] = true;
    (*graph)[from_right][left] = true; (*reverse)[left][from_right] = true;
}

fn long perfect_phylogeny_three_state_2sat(long* input, usz length)
    @export("perfect_phylogeny_three_state_2sat") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long taxa_raw = input[0], characters_raw = input[1];
    if (taxa_raw < 1 || taxa_raw > MAX_TAXA || characters_raw < 0 || characters_raw > MAX_CHARACTERS) return -1;
    int taxa = (int)taxa_raw, characters = (int)characters_raw;
    if (length != 2 + (usz)(taxa * characters)) return -1;

    ushort[MAX_CHARACTERS][3] masks = zeroed;
    for (int taxon = 0; taxon < taxa; taxon++) for (int character = 0; character < characters; character++) {
        long state = input[2 + taxon * characters + character];
        if (state < 0 || state > 2) return -1;
        masks[character][(int)state] |= (ushort)1 << taxon;
    }

    bool[MAX_LITERALS][MAX_LITERALS] graph = zeroed, reverse = zeroed;
    for (int character = 0; character < characters; character++) {
        int v0 = 3 * character, v1 = v0 + 1, v2 = v0 + 2;
        add_clause(&graph, &reverse, 2 * v0, 2 * v1);
        add_clause(&graph, &reverse, 2 * v0, 2 * v2);
        add_clause(&graph, &reverse, 2 * v1, 2 * v2);
        int present = 0, missing = -1;
        for (int state = 0; state < 3; state++) {
            if (masks[character][state] != 0) present++;
            else missing = state;
        }
        if (present == 2) {
            int absent_literal = 2 * (3 * character + missing) + 1;
            add_clause(&graph, &reverse, absent_literal, absent_literal);
        }
    }
    ushort universe = ((ushort)1 << taxa) - 1;
    for (int a = 0; a < characters; a++) for (int b = a + 1; b < characters; b++) {
        for (int sa = 0; sa < 3; sa++) for (int sb = 0; sb < 3; sb++) {
            ushort left = masks[a][sa], right = masks[b][sb];
            ushort both = left & right;
            ushort left_only = left & universe & ~right;
            ushort right_only = right & universe & ~left;
            ushort neither = universe & ~(left | right);
            if (both != 0 && left_only != 0 && right_only != 0 && neither != 0)
                add_clause(&graph, &reverse, 2 * (3 * a + sa) + 1, 2 * (3 * b + sb) + 1);
        }
    }

    int literal_count = 6 * characters;
    bool[MAX_LITERALS] seen = zeroed;
    int[MAX_LITERALS] order = zeroed, stack = zeroed, next_index = zeroed;
    int order_count = 0;
    for (int start = 0; start < literal_count; start++) if (!seen[start]) {
        int top = 1; stack[0] = start; seen[start] = true; next_index[start] = 0;
        while (top > 0) {
            int vertex = stack[top - 1], next = next_index[vertex];
            while (next < literal_count && (!graph[vertex][next] || seen[next])) next++;
            if (next < literal_count) {
                next_index[vertex] = next + 1; seen[next] = true;
                stack[top++] = next; next_index[next] = 0;
            } else { order[order_count++] = vertex; top--; }
        }
    }
    int[MAX_LITERALS] component; for (int i = 0; i < literal_count; i++) component[i] = -1;
    int label = 0;
    while (order_count > 0) {
        int start = order[--order_count];
        if (component[start] >= 0) continue;
        int top = 1; stack[0] = start; component[start] = label;
        while (top > 0) {
            int vertex = stack[--top];
            for (int next = 0; next < literal_count; next++) if (reverse[vertex][next] && component[next] < 0) {
                component[next] = label; stack[top++] = next;
            }
        }
        label++;
    }
    for (int variable = 0; variable < 3 * characters; variable++)
        if (component[2 * variable] == component[2 * variable + 1]) return 0;
    return 1;
}
