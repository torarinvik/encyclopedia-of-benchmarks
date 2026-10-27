#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_M = 6, MAX_W = 6, MAX_INPUT = 74, MAX_OUTPUT = 48, MAX_STEPS = 121 };

static void put64(uint8_t *output, size_t position, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[position + byte] = (uint8_t)(bits >> (8u * byte));
}

static bool man_prefers(size_t man, size_t a, size_t b,
                        const int64_t men_rank[MAX_M][MAX_W],
                        const int64_t woman_partner[MAX_W])
{
    if (men_rank[man][a] != men_rank[man][b]) return men_rank[man][a] < men_rank[man][b];
    bool a_maiden = woman_partner[a] == -1;
    bool b_maiden = woman_partner[b] == -1;
    if (a_maiden != b_maiden) return a_maiden;
    return a < b;
}

static bool uncertain(size_t man, size_t m, size_t w,
                      const int64_t men_rank[MAX_M][MAX_W],
                      const bool live[MAX_M][MAX_W],
                      const int64_t assignment[MAX_M], const int64_t woman_partner[MAX_W],
                      const int status[MAX_M])
{
    if (status[man] != 0 || assignment[man] < 0) return false;
    size_t fiance = (size_t)assignment[man];
    for (size_t woman = 0; woman < w; ++woman)
        if (live[man][woman] && woman != fiance &&
            (men_rank[man][woman] < men_rank[man][fiance] ||
             (men_rank[man][woman] == men_rank[man][fiance] &&
              woman_partner[woman] == -1 && woman_partner[fiance] != -1))) return true;
    (void)m;
    return false;
}

static bool woman_prefers(size_t woman, size_t candidate, size_t incumbent,
                          bool incumbent_uncertain,
                          const int64_t women_rank[MAX_W][MAX_M],
                          const int status[MAX_M])
{
    if (incumbent_uncertain) return true; /* flighty: any certain suitor outranks an uncertain fiancé */
    if (women_rank[woman][candidate] != women_rank[woman][incumbent])
        return women_rank[woman][candidate] < women_rank[woman][incumbent];
    if (status[candidate] != status[incumbent]) return status[candidate] > status[incumbent];
    return candidate < incumbent;
}

int64_t kiraly_max_smt_i_approx(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4u || length > MAX_INPUT) return -1;
    int64_t m64 = input[0], w64 = input[1];
    if (m64 < 1 || m64 > MAX_M || w64 < 1 || w64 > MAX_W) return -1;
    size_t m = (size_t)m64, w = (size_t)w64;
    if (length != 2u + 2u * m * w) return -1;

    int64_t men_rank[MAX_M][MAX_W] = {{0}};
    int64_t women_rank[MAX_W][MAX_M] = {{0}};
    bool live[MAX_M][MAX_W] = {{false}};
    int64_t assignment[MAX_M];
    int64_t woman_partner[MAX_W];
    int status[MAX_M] = {0}; /* 0 lad, 1 bachelor, 2 old bachelor */
    size_t women_offset = 2u + m * w;
    for (size_t man = 0; man < m; ++man) {
        assignment[man] = -1;
        for (size_t woman = 0; woman < w; ++woman) {
            int64_t rank = input[2u + man * w + woman];
            if (rank < -1 || rank >= MAX_W) return -1;
            men_rank[man][woman] = rank;
        }
    }
    for (size_t woman = 0; woman < w; ++woman) woman_partner[woman] = -1;
    for (size_t woman = 0; woman < w; ++woman)
        for (size_t man = 0; man < m; ++man) {
            int64_t rank = input[women_offset + woman * m + man];
            if (rank < -1 || rank >= MAX_M) return -1;
            women_rank[woman][man] = rank;
        }
    for (size_t man = 0; man < m; ++man)
        for (size_t woman = 0; woman < w; ++woman) {
            bool man_accepts = men_rank[man][woman] >= 0;
            bool woman_accepts = women_rank[woman][man] >= 0;
            if (man_accepts != woman_accepts) return -1;
            live[man][woman] = man_accepts;
        }

    size_t output_bytes = 8u * m;
    if (output == NULL || capacity < output_bytes) return -2;

    size_t steps = 0;
    while (true) {
        if (++steps > MAX_STEPS) return -1;
        size_t man = m;
        for (size_t candidate = 0; candidate < m; ++candidate)
            if (status[candidate] != 2 && assignment[candidate] == -1) { man = candidate; break; }
        if (man == m) break;

        size_t woman = w;
        for (size_t candidate = 0; candidate < w; ++candidate)
            if (live[man][candidate] &&
                (woman == w || man_prefers(man, candidate, woman, men_rank, woman_partner))) woman = candidate;
        if (woman == w) {
            if (status[man] == 0) {
                status[man] = 1;
                for (size_t candidate = 0; candidate < w; ++candidate)
                    live[man][candidate] = men_rank[man][candidate] >= 0;
            } else {
                status[man] = 2;
            }
            continue;
        }

        int64_t incumbent64 = woman_partner[woman];
        if (incumbent64 < 0) {
            assignment[man] = (int64_t)woman;
            woman_partner[woman] = (int64_t)man;
            continue;
        }
        size_t incumbent = (size_t)incumbent64;
        bool incumbent_is_uncertain = uncertain(incumbent, m, w, men_rank, live, assignment, woman_partner, status);
        if (woman_prefers(woman, man, incumbent, incumbent_is_uncertain, women_rank, status)) {
            assignment[incumbent] = -1;
            woman_partner[woman] = -1;
            if (!incumbent_is_uncertain) live[incumbent][woman] = false;
            assignment[man] = (int64_t)woman;
            woman_partner[woman] = (int64_t)man;
        } else {
            live[man][woman] = false;
        }
    }

    uint8_t staged[MAX_OUTPUT] = {0};
    for (size_t man = 0; man < m; ++man) put64(staged, 8u * man, assignment[man]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
