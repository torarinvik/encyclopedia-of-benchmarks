#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t clock_patience_simulation(const std::int64_t *values,
                                                   std::size_t length) {
    constexpr std::size_t pile_count = 13;
    constexpr std::size_t cards_per_pile = 4;
    constexpr std::size_t card_count = pile_count * cards_per_pile;
    if (values == nullptr || length != card_count) return -1;

    std::array<std::size_t, pile_count + 1> rank_counts{};
    for (std::size_t index = 0; index < card_count; ++index) {
        const std::int64_t rank = values[index];
        if (rank < 1 || rank > static_cast<std::int64_t>(pile_count)) return -1;
        ++rank_counts[static_cast<std::size_t>(rank)];
    }
    for (std::size_t rank = 1; rank <= pile_count; ++rank) {
        if (rank_counts[rank] != cards_per_pile) return -1;
    }

    std::array<std::size_t, pile_count> next_card{};
    std::size_t pile = pile_count - 1;
    std::size_t revealed = 0;
    while (next_card[pile] < cards_per_pile) {
        const std::int64_t rank = values[pile * cards_per_pile + next_card[pile]];
        ++next_card[pile];
        ++revealed;
        pile = static_cast<std::size_t>(rank - 1);
    }
    return revealed == card_count ? 1 : 0;
}
