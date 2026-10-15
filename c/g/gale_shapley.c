/* Proposer-proposing Gale-Shapley stable matching for complete preferences. */
#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

int64_t gale_shapley(const int64_t *values, size_t length,
                     uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > 66) return -2;
    if (values[0] < 0 || values[0] > 5) return -2;
    const size_t count = (size_t)values[0];
    if (length != 1 + 2 * count * count) return -2;

    int64_t ranks[5][5] = {{0}};
    bool seen[5];
    for (size_t proposer = 0; proposer < count; ++proposer) {
        for (size_t other = 0; other < count; ++other) seen[other] = false;
        for (size_t rank = 0; rank < count; ++rank) {
            const int64_t accepter = values[1 + proposer * count + rank];
            if (accepter < 0 || (uint64_t)accepter >= count || seen[(size_t)accepter]) return -2;
            seen[(size_t)accepter] = true;
        }
    }
    const size_t accepter_offset = 1 + count * count;
    for (size_t accepter = 0; accepter < count; ++accepter) {
        for (size_t other = 0; other < count; ++other) seen[other] = false;
        for (size_t rank = 0; rank < count; ++rank) {
            const int64_t proposer = values[accepter_offset + accepter * count + rank];
            if (proposer < 0 || (uint64_t)proposer >= count || seen[(size_t)proposer]) return -2;
            seen[(size_t)proposer] = true;
            ranks[accepter][(size_t)proposer] = (int64_t)rank;
        }
    }
    if (output_capacity < count || (count != 0 && output == NULL)) return -2;

    int64_t matched_proposer[5];
    int64_t matched_accepter[5];
    size_t next_choice[5] = {0};
    for (size_t index = 0; index < count; ++index) {
        matched_proposer[index] = -1;
        matched_accepter[index] = -1;
    }
    for (;;) {
        size_t proposer = 0;
        while (proposer < count && matched_accepter[proposer] != -1) ++proposer;
        if (proposer == count) break;
        const size_t preference_index = 1 + proposer * count + next_choice[proposer]++;
        const size_t accepter = (size_t)values[preference_index];
        const int64_t current = matched_proposer[accepter];
        if (current == -1 || ranks[accepter][proposer] < ranks[accepter][(size_t)current]) {
            if (current != -1) matched_accepter[(size_t)current] = -1;
            matched_proposer[accepter] = (int64_t)proposer;
            matched_accepter[proposer] = (int64_t)accepter;
        }
    }
    for (size_t proposer = 0; proposer < count; ++proposer)
        output[proposer] = (uint8_t)matched_accepter[proposer];
    return (int64_t)count;
}
