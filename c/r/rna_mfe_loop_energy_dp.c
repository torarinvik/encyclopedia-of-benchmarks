#include <stddef.h>
#include <stdint.h>

#define MAX_N 12
#define MAX_PAIRS 36
#define TABLE_VALUES 234
#define MAX_INPUT 247
#define MAX_OUTPUT 112
#define INF INT64_C(1152921504606846976)

static int pair_type_of(int64_t left, int64_t right) {
    if (left == 0 && right == 3) return 0;
    if (left == 3 && right == 0) return 1;
    if (left == 1 && right == 2) return 2;
    if (left == 2 && right == 1) return 3;
    if (left == 2 && right == 3) return 4;
    if (left == 3 && right == 2) return 5;
    return -1;
}

static int lex_less_mask(uint64_t left, uint64_t right, size_t count) {
    size_t li = 0, ri = 0;
    for (;;) {
        while (li < count && ((left >> li) & 1U) == 0) ++li;
        while (ri < count && ((right >> ri) & 1U) == 0) ++ri;
        if (li == count || ri == count) return li == count && ri < count;
        if (li != ri) return li < ri;
        ++li; ++ri;
    }
}

static int64_t loop_cost(const int64_t *input, size_t n, int kind, int unpaired, int children) {
    return input[1 + n + (size_t)kind * 39 + (size_t)unpaired * 3 + (size_t)children];
}

static void put64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t rna_mfe_loop_energy_dp(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 239 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0];
    if (n64 < 4 || n64 > MAX_N || length != 1 + (size_t)n64 + TABLE_VALUES) return -1;
    size_t n = (size_t)n64;
    int64_t bases[MAX_N];
    for (size_t i = 0; i < n; ++i) { bases[i] = input[1 + i]; if (bases[i] < 0 || bases[i] > 3) return -1; }
    for (size_t i = 1 + n; i < length; ++i) if (input[i] < -1000 || input[i] > 1000) return -1;

    int types[MAX_N][MAX_N], ids[MAX_N][MAX_N];
    for (size_t i = 0; i < MAX_N; ++i) for (size_t j = 0; j < MAX_N; ++j) { types[i][j] = -1; ids[i][j] = -1; }
    int pair_i[MAX_PAIRS], pair_j[MAX_PAIRS];
    size_t pair_count = 0;
    for (size_t i = 0; i < n; ++i) for (size_t j = i + 4; j < n; ++j) {
        int kind = pair_type_of(bases[i], bases[j]);
        if (kind >= 0) { types[i][j] = kind; ids[i][j] = (int)pair_count; pair_i[pair_count] = (int)i; pair_j[pair_count] = (int)j; ++pair_count; }
    }

    int64_t v_energy[MAX_N][MAX_N];
    uint64_t v_mask[MAX_N][MAX_N] = {{0}};
    for (size_t i = 0; i < MAX_N; ++i) for (size_t j = 0; j < MAX_N; ++j) v_energy[i][j] = INF;
    for (size_t span = 4; span < n; ++span) for (size_t i = 0; i + span < n; ++i) {
        size_t j = i + span;
        int kind = types[i][j];
        if (kind < 0) continue;
        uint64_t outer = UINT64_C(1) << (unsigned)ids[i][j];
        int64_t best = INF;
        uint64_t best_mask = 0;

        int64_t candidate = loop_cost(input, n, kind, (int)span - 1, 0);
        if (candidate < best || (candidate == best && lex_less_mask(outer, best_mask, pair_count))) { best = candidate; best_mask = outer; }

        for (size_t a = i + 1; a < j; ++a) for (size_t b = a + 4; b < j; ++b) {
            if (ids[a][b] < 0 || v_energy[a][b] == INF) continue;
            int unpaired = (int)(a - i - 1 + j - b - 1);
            candidate = loop_cost(input, n, kind, unpaired, 1) + v_energy[a][b];
            uint64_t mask = outer | v_mask[a][b];
            if (candidate < best || (candidate == best && lex_less_mask(mask, best_mask, pair_count))) { best = candidate; best_mask = mask; }
        }

        for (size_t a = i + 1; a < j; ++a) for (size_t b = a + 4; b < j; ++b) {
            if (ids[a][b] < 0 || v_energy[a][b] == INF) continue;
            for (size_t c = b + 1; c < j; ++c) for (size_t d = c + 4; d < j; ++d) {
                if (ids[c][d] < 0 || v_energy[c][d] == INF) continue;
                int unpaired = (int)(a - i - 1 + c - b - 1 + j - d - 1);
                candidate = loop_cost(input, n, kind, unpaired, 2) + v_energy[a][b] + v_energy[c][d];
                uint64_t mask = outer | v_mask[a][b] | v_mask[c][d];
                if (candidate < best || (candidate == best && lex_less_mask(mask, best_mask, pair_count))) { best = candidate; best_mask = mask; }
            }
        }
        v_energy[i][j] = best;
        v_mask[i][j] = best_mask;
    }

    int64_t w_energy[MAX_N] = {0};
    uint64_t w_mask[MAX_N] = {0};
    for (size_t j = 0; j < n; ++j) {
        int64_t best = j == 0 ? 0 : w_energy[j - 1];
        uint64_t best_mask = j == 0 ? 0 : w_mask[j - 1];
        for (size_t i = 0; i + 4 <= j; ++i) {
            if (types[i][j] < 0 || v_energy[i][j] == INF) continue;
            int64_t prefix = i == 0 ? 0 : w_energy[i - 1];
            uint64_t mask = (i == 0 ? 0 : w_mask[i - 1]) | v_mask[i][j];
            int64_t value = prefix + v_energy[i][j];
            if (value < best || (value == best && lex_less_mask(mask, best_mask, pair_count))) { best = value; best_mask = mask; }
        }
        w_energy[j] = best;
        w_mask[j] = best_mask;
    }

    int64_t pair_total = 0;
    for (size_t p = 0; p < pair_count; ++p) if ((w_mask[n - 1] >> p) & 1U) ++pair_total;
    size_t bytes = 8 * (2 + 2 * (size_t)pair_total);
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT];
    put64(staged, 0, w_energy[n - 1]); put64(staged, 8, pair_total);
    size_t at = 2;
    for (size_t p = 0; p < pair_count; ++p) if ((w_mask[n - 1] >> p) & 1U) {
        put64(staged, 8 * at++, pair_i[p]); put64(staged, 8 * at++, pair_j[p]);
    }
    for (size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)bytes;
}
