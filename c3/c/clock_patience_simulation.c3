module clock_patience_simulation;

const usz PILE_COUNT = 13;
const usz CARDS_PER_PILE = 4;
const usz CARD_COUNT = 52;
const long MAX_RANK = 13;

fn long clock_patience_simulation(long* values, usz length) @export("clock_patience_simulation") {
    if (values == null || length != CARD_COUNT) return -1;
    long[14] rank_counts = {0};
    for (usz index = 0; index < CARD_COUNT; index++) {
        long rank = values[index];
        if (rank < 1 || rank > MAX_RANK) return -1;
        rank_counts[(usz)rank] += 1;
    }
    for (usz rank = 1; rank <= PILE_COUNT; rank++) {
        if (rank_counts[rank] != (long)CARDS_PER_PILE) return -1;
    }

    usz[13] next_card = {0};
    usz pile = 12;
    usz revealed = 0;
    while (next_card[pile] < 4) {
        long rank = values[pile * 4 + next_card[pile]];
        next_card[pile] += 1;
        revealed += 1;
        pile = (usz)(rank - 1);
    }
    return revealed == CARD_COUNT ? 1 : 0;
}
