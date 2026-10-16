/* Count Player 1 wins in the pinned 1,000-deal poker dataset. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t deal_count = 1000;
constexpr std::size_t values_per_deal = 10;

void rank_hand(const std::int64_t cards[5], std::int64_t score[6]) noexcept
{
    std::int64_t ranks[5], suits[5], counts[15] = {};
    for (int i = 0; i < 5; ++i) {
        ranks[i] = cards[i] / 4 + 2;
        suits[i] = cards[i] % 4;
        ++counts[ranks[i]];
    }
    for (int i = 1; i < 5; ++i) {
        const auto value = ranks[i];
        int j = i;
        while (j > 0 && ranks[j - 1] < value) { ranks[j] = ranks[j - 1]; --j; }
        ranks[j] = value;
    }
    for (int i = 0; i < 6; ++i) score[i] = 0;
    bool flush = true;
    for (int i = 1; i < 5; ++i) if (suits[i] != suits[0]) flush = false;
    bool distinct = true;
    for (int rank = 2; rank <= 14; ++rank) if (counts[rank] > 1) distinct = false;
    std::int64_t straight_high = 0;
    if (distinct && ranks[0] - ranks[4] == 4) straight_high = ranks[0];
    else if (distinct && ranks[0] == 14 && ranks[1] == 5 && ranks[2] == 4 && ranks[3] == 3 && ranks[4] == 2)
        straight_high = 5;
    std::int64_t four = 0, three = 0, pair_high = 0, pair_low = 0;
    std::int64_t singles[5] = {};
    int single_count = 0;
    for (std::int64_t rank = 14; rank >= 2; --rank) {
        if (counts[rank] == 4) four = rank;
        else if (counts[rank] == 3) three = rank;
        else if (counts[rank] == 2) { if (pair_high == 0) pair_high = rank; else pair_low = rank; }
        else if (counts[rank] == 1) singles[single_count++] = rank;
    }
    if (flush && straight_high != 0) { score[0] = straight_high == 14 ? 9 : 8; score[1] = straight_high; }
    else if (four != 0) { score[0] = 7; score[1] = four; score[2] = singles[0]; }
    else if (three != 0 && pair_high != 0) { score[0] = 6; score[1] = three; score[2] = pair_high; }
    else if (flush) { score[0] = 5; for (int i = 0; i < 5; ++i) score[i + 1] = ranks[i]; }
    else if (straight_high != 0) { score[0] = 4; score[1] = straight_high; }
    else if (three != 0) { score[0] = 3; score[1] = three; score[2] = singles[0]; score[3] = singles[1]; }
    else if (pair_low != 0) { score[0] = 2; score[1] = pair_high; score[2] = pair_low; score[3] = singles[0]; }
    else if (pair_high != 0) { score[0] = 1; score[1] = pair_high; score[2] = singles[0]; score[3] = singles[1]; score[4] = singles[2]; }
    else { score[0] = 0; for (int i = 0; i < 5; ++i) score[i + 1] = ranks[i]; }
}

bool player_one_wins(const std::int64_t first[6], const std::int64_t second[6]) noexcept
{
    for (int i = 0; i < 6; ++i) if (first[i] != second[i]) return first[i] > second[i];
    return false;
}
}

extern "C" std::int64_t problem54(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != deal_count * values_per_deal) return -1;
    std::int64_t wins = 0;
    for (std::size_t deal = 0; deal < deal_count; ++deal) {
        const std::size_t offset = deal * values_per_deal;
        for (std::size_t i = 0; i < values_per_deal; ++i) {
            const auto card = input[offset + i];
            if (card < 0 || card >= 52) return -1;
            for (std::size_t previous = 0; previous < i; ++previous)
                if (input[offset + previous] == card) return -1;
        }
        std::int64_t first_cards[5], second_cards[5], first_score[6], second_score[6];
        for (int i = 0; i < 5; ++i) { first_cards[i] = input[offset + i]; second_cards[i] = input[offset + 5 + i]; }
        rank_hand(first_cards, first_score);
        rank_hand(second_cards, second_score);
        wins += player_one_wins(first_score, second_score);
    }
    return wins;
}
