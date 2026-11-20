/* Clean-room bounded deterministic Sequitur grammar profile. */
#include <stddef.h>
#include <stdint.h>

enum { RULE_CAPACITY = 256, SYMBOL_CAPACITY = 64, TERMINAL_BASE = 0, NONTERMINAL_BASE = 256 };
typedef struct {
    int32_t symbols[RULE_CAPACITY][SYMBOL_CAPACITY];
    int length[RULE_CAPACITY];
    uint8_t live[RULE_CAPACITY];
    int next_rule;
} Grammar;
typedef struct { int found, r1, p1, r2, p2, left, right; } Duplicate;

static void replace_pair(Grammar *g, int rule, int position, int32_t token) {
    for (int i = position + 2; i < g->length[rule]; ++i)
        g->symbols[rule][i - 1] = g->symbols[rule][i];
    --g->length[rule];
    g->symbols[rule][position] = token;
}

static Duplicate find_duplicate(const Grammar *g) {
    Duplicate out = {0, 0, 0, 0, 0, 0, 0};
    for (int r1 = 0; r1 < g->next_rule; ++r1) if (g->live[r1]) {
        for (int p1 = 0; p1 + 1 < g->length[r1]; ++p1) {
            int32_t left = g->symbols[r1][p1], right = g->symbols[r1][p1 + 1];
            for (int r2 = r1; r2 < g->next_rule; ++r2) if (g->live[r2]) {
                int start = r2 == r1 ? p1 + 2 : 0;
                for (int p2 = start; p2 + 1 < g->length[r2]; ++p2) {
                    if (g->symbols[r2][p2] == left && g->symbols[r2][p2 + 1] == right) {
                        out.found = 1; out.r1 = r1; out.p1 = p1; out.r2 = r2; out.p2 = p2;
                        out.left = left; out.right = right; return out;
                    }
                }
            }
        }
    }
    return out;
}

static int cleanup_one(Grammar *g) {
    for (int target = 1; target < g->next_rule; ++target) if (g->live[target]) {
        int references = 0, parent = -1, position = -1;
        int32_t token = NONTERMINAL_BASE + target;
        for (int rule = 0; rule < g->next_rule; ++rule) if (g->live[rule]) {
            for (int i = 0; i < g->length[rule]; ++i) if (g->symbols[rule][i] == token) {
                ++references; parent = rule; position = i;
            }
        }
        if (references == 0) { g->live[target] = 0; g->length[target] = 0; return 1; }
        if (references == 1) {
            int copied[SYMBOL_CAPACITY], replacement_length = g->length[target];
            for (int i = 0; i < replacement_length; ++i) copied[i] = g->symbols[target][i];
            int delta = replacement_length - 1, old_length = g->length[parent];
            for (int i = old_length - 1; i > position; --i)
                g->symbols[parent][i + delta] = g->symbols[parent][i];
            for (int i = 0; i < replacement_length; ++i) g->symbols[parent][position + i] = copied[i];
            g->length[parent] += delta;
            g->live[target] = 0; g->length[target] = 0; return 1;
        }
    }
    return 0;
}

static void normalize(Grammar *g) {
    for (;;) {
        while (cleanup_one(g)) { }
        Duplicate d = find_duplicate(g);
        if (!d.found) return;
        int existing = -1;
        for (int rule = 1; rule < g->next_rule; ++rule)
            if (g->live[rule] && g->length[rule] == 2 &&
                g->symbols[rule][0] == d.left && g->symbols[rule][1] == d.right) { existing = rule; break; }
        if (existing >= 0) {
            int rule = d.r1, position = d.p1;
            if (rule == existing && position == 0) { rule = d.r2; position = d.p2; }
            replace_pair(g, rule, position, NONTERMINAL_BASE + existing);
        } else {
            int fresh = g->next_rule++;
            g->live[fresh] = 1; g->length[fresh] = 2;
            g->symbols[fresh][0] = d.left; g->symbols[fresh][1] = d.right;
            int32_t token = NONTERMINAL_BASE + fresh;
            replace_pair(g, d.r2, d.p2, token);
            replace_pair(g, d.r1, d.p1, token);
        }
    }
}

int64_t sequitur_grammar_induction(const int64_t *input, size_t length) {
    if (!input || length < 1 || length > 66) return -1;
    if (input[0] < 0 || input[0] > 64 || length != (size_t)input[0] + 1) return -1;
    size_t n = (size_t)input[0];
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    Grammar g = {0}; g.live[0] = 1; g.next_rule = 1;
    for (size_t i = 0; i < n; ++i) {
        g.symbols[0][g.length[0]++] = (int32_t)(TERMINAL_BASE + input[i + 1]);
        normalize(&g);
    }
    int rules = 0, symbols = 0;
    for (int rule = 0; rule < g.next_rule; ++rule) if (g.live[rule]) {
        if (rule != 0) ++rules;
        symbols += g.length[rule];
    }
    return (int64_t)1000 * rules + symbols;
}
