#include <stddef.h>
#include <stdint.h>

#define CLOCK_PILE_COUNT 13
#define CLOCK_CARDS_PER_PILE 4
#define CLOCK_CARD_COUNT 52

int64_t clock_patience_simulation(const int64_t *values, size_t length) {
    if (values == NULL || length != CLOCK_CARD_COUNT) return -1;
    size_t rank_counts[CLOCK_PILE_COUNT + 1] = {0};
    for (size_t index = 0; index < CLOCK_CARD_COUNT; ++index) {
        const int64_t rank = values[index];
        if (rank < 1 || rank > CLOCK_PILE_COUNT) return -1;
        ++rank_counts[(size_t)rank];
    }
    for (size_t rank = 1; rank <= CLOCK_PILE_COUNT; ++rank) {
        if (rank_counts[rank] != CLOCK_CARDS_PER_PILE) return -1;
    }

    size_t next_card[CLOCK_PILE_COUNT] = {0};
    size_t pile = CLOCK_PILE_COUNT - 1;
    size_t revealed = 0;
    while (next_card[pile] < CLOCK_CARDS_PER_PILE) {
        const size_t offset = pile * CLOCK_CARDS_PER_PILE + next_card[pile];
        const int64_t rank = values[offset];
        ++next_card[pile];
        ++revealed;
        pile = (size_t)(rank - 1);
    }
    return revealed == CLOCK_CARD_COUNT ? 1 : 0;
}
