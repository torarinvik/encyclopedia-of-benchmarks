/* Count Player 1 wins in the pinned 1,000-deal poker dataset. */
#include <stddef.h>
#include <stdint.h>

#define DEAL_COUNT 1000
#define VALUES_PER_DEAL 10

static void rank_hand(const int64_t cards[5], int64_t score[6])
{
    int64_t ranks[5], suits[5], counts[15] = {0};
    for (int i = 0; i < 5; ++i) {
        ranks[i] = cards[i] / 4 + 2;
        suits[i] = cards[i] % 4;
        ++counts[ranks[i]];
    }
    for (int i = 1; i < 5; ++i) {
        const int64_t value = ranks[i];
        int j = i;
        while (j > 0 && ranks[j - 1] < value) { ranks[j] = ranks[j - 1]; --j; }
        ranks[j] = value;
    }
    for (int i = 0; i < 6; ++i) score[i] = 0;

    int flush = 1;
    for (int i = 1; i < 5; ++i) if (suits[i] != suits[0]) flush = 0;
    int distinct = 1;
    for (int rank = 2; rank <= 14; ++rank) if (counts[rank] > 1) distinct = 0;
    int64_t straight_high = 0;
    if (distinct && ranks[0] - ranks[4] == 4) straight_high = ranks[0];
    else if (distinct && ranks[0] == 14 && ranks[1] == 5 && ranks[2] == 4 && ranks[3] == 3 && ranks[4] == 2)
        straight_high = 5;

    int64_t four = 0, three = 0, pair_high = 0, pair_low = 0;
    int64_t singles[5] = {0};
    int single_count = 0;
    for (int64_t rank = 14; rank >= 2; --rank) {
        if (counts[rank] == 4) four = rank;
        else if (counts[rank] == 3) three = rank;
        else if (counts[rank] == 2) {
            if (pair_high == 0) pair_high = rank;
            else pair_low = rank;
        } else if (counts[rank] == 1) singles[single_count++] = rank;
    }

    if (flush && straight_high != 0) {
        score[0] = straight_high == 14 ? 9 : 8;
        score[1] = straight_high;
    } else if (four != 0) {
        score[0] = 7; score[1] = four; score[2] = singles[0];
    } else if (three != 0 && pair_high != 0) {
        score[0] = 6; score[1] = three; score[2] = pair_high;
    } else if (flush) {
        score[0] = 5;
        for (int i = 0; i < 5; ++i) score[i + 1] = ranks[i];
    } else if (straight_high != 0) {
        score[0] = 4; score[1] = straight_high;
    } else if (three != 0) {
        score[0] = 3; score[1] = three; score[2] = singles[0]; score[3] = singles[1];
    } else if (pair_low != 0) {
        score[0] = 2; score[1] = pair_high; score[2] = pair_low; score[3] = singles[0];
    } else if (pair_high != 0) {
        score[0] = 1; score[1] = pair_high;
        score[2] = singles[0]; score[3] = singles[1]; score[4] = singles[2];
    } else {
        score[0] = 0;
        for (int i = 0; i < 5; ++i) score[i + 1] = ranks[i];
    }
}

static int player_one_wins(const int64_t first[6], const int64_t second[6])
{
    for (int i = 0; i < 6; ++i) {
        if (first[i] != second[i]) return first[i] > second[i];
    }
    return 0;
}

int64_t problem54(const int64_t *input, size_t length)
{
    if (input == NULL || length != DEAL_COUNT * VALUES_PER_DEAL) return -1;
    int64_t wins = 0;
    for (size_t deal = 0; deal < DEAL_COUNT; ++deal) {
        const size_t offset = deal * VALUES_PER_DEAL;
        for (size_t i = 0; i < VALUES_PER_DEAL; ++i) {
            const int64_t card = input[offset + i];
            if (card < 0 || card >= 52) return -1;
            for (size_t previous = 0; previous < i; ++previous)
                if (input[offset + previous] == card) return -1;
        }
        int64_t first_cards[5], second_cards[5], first_score[6], second_score[6];
        for (int i = 0; i < 5; ++i) {
            first_cards[i] = input[offset + (size_t)i];
            second_cards[i] = input[offset + 5 + (size_t)i];
        }
        rank_hand(first_cards, first_score);
        rank_hand(second_cards, second_score);
        wins += player_one_wins(first_score, second_score);
    }
    return wins;
}
