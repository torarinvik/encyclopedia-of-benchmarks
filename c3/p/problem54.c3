module problem54;

const usz DEAL_COUNT = 1000;
const usz VALUES_PER_DEAL = 10;

fn void rank_hand(long* cards, long* score) {
    long[5] ranks;
    long[5] suits;
    long[15] counts = {0};
    for (usz i = 0; i < 5; i++) {
        ranks[i] = cards[i] / 4 + 2;
        suits[i] = cards[i] % 4;
        counts[(usz)ranks[i]]++;
    }
    for (int i = 1; i < 5; i++) {
        long value = ranks[i];
        int j = i;
        while (j > 0 && ranks[j - 1] < value) { ranks[j] = ranks[j - 1]; j--; }
        ranks[j] = value;
    }
    for (usz i = 0; i < 6; i++) score[i] = 0;
    bool flush = true;
    for (usz i = 1; i < 5; i++) if (suits[i] != suits[0]) flush = false;
    bool distinct = true;
    for (usz rank = 2; rank <= 14; rank++) if (counts[rank] > 1) distinct = false;
    long straight_high = 0;
    if (distinct && ranks[0] - ranks[4] == 4) straight_high = ranks[0];
    else if (distinct && ranks[0] == 14 && ranks[1] == 5 && ranks[2] == 4 && ranks[3] == 3 && ranks[4] == 2) straight_high = 5;
    long four = 0, three = 0, pair_high = 0, pair_low = 0;
    long[5] singles = {0};
    int single_count = 0;
    for (long rank = 14; rank >= 2; rank--) {
        if (counts[(usz)rank] == 4) four = rank;
        else if (counts[(usz)rank] == 3) three = rank;
        else if (counts[(usz)rank] == 2) { if (pair_high == 0) pair_high = rank; else pair_low = rank; }
        else if (counts[(usz)rank] == 1) singles[single_count++] = rank;
    }
    if (flush && straight_high != 0) { score[0] = straight_high == 14 ? 9 : 8; score[1] = straight_high; }
    else if (four != 0) { score[0] = 7; score[1] = four; score[2] = singles[0]; }
    else if (three != 0 && pair_high != 0) { score[0] = 6; score[1] = three; score[2] = pair_high; }
    else if (flush) { score[0] = 5; for (usz i = 0; i < 5; i++) score[i + 1] = ranks[i]; }
    else if (straight_high != 0) { score[0] = 4; score[1] = straight_high; }
    else if (three != 0) { score[0] = 3; score[1] = three; score[2] = singles[0]; score[3] = singles[1]; }
    else if (pair_low != 0) { score[0] = 2; score[1] = pair_high; score[2] = pair_low; score[3] = singles[0]; }
    else if (pair_high != 0) { score[0] = 1; score[1] = pair_high; score[2] = singles[0]; score[3] = singles[1]; score[4] = singles[2]; }
    else { score[0] = 0; for (usz i = 0; i < 5; i++) score[i + 1] = ranks[i]; }
}

fn bool player_one_wins(long* first, long* second) {
    for (usz i = 0; i < 6; i++) if (first[i] != second[i]) return first[i] > second[i];
    return false;
}

fn long problem54(long* input, usz length) @export("problem54") {
    if (input == null || length != DEAL_COUNT * VALUES_PER_DEAL) return -1;
    long wins = 0;
    for (usz deal = 0; deal < DEAL_COUNT; deal++) {
        usz offset = deal * VALUES_PER_DEAL;
        for (usz i = 0; i < VALUES_PER_DEAL; i++) {
            long card = input[offset + i];
            if (card < 0 || card >= 52) return -1;
            for (usz previous = 0; previous < i; previous++) if (input[offset + previous] == card) return -1;
        }
        long[5] first_cards, second_cards;
        long[6] first_score, second_score;
        for (usz i = 0; i < 5; i++) { first_cards[i] = input[offset + i]; second_cards[i] = input[offset + 5 + i]; }
        rank_hand(&first_cards[0], &first_score[0]);
        rank_hand(&second_cards[0], &second_score[0]);
        if (player_one_wins(&first_score[0], &second_score[0])) wins++;
    }
    return wins;
}
