/* Proposer-proposing Gale-Shapley stable matching for complete preferences. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gale_shapley(const std::int64_t *values, std::size_t length,
                                     std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 1 || length > 66 || values[0] < 0 || values[0] > 5) return -2;
    const auto count = static_cast<std::size_t>(values[0]);
    if (length != 1 + 2 * count * count) return -2;
    std::int64_t ranks[5][5]{};
    bool seen[5]{};
    for (std::size_t proposer = 0; proposer < count; ++proposer) {
        for (std::size_t index = 0; index < count; ++index) seen[index] = false;
        for (std::size_t rank = 0; rank < count; ++rank) {
            const auto accepter = values[1 + proposer * count + rank];
            if (accepter < 0 || static_cast<std::uint64_t>(accepter) >= count || seen[accepter]) return -2;
            seen[accepter] = true;
        }
    }
    const auto accepter_offset = 1 + count * count;
    for (std::size_t accepter = 0; accepter < count; ++accepter) {
        for (std::size_t index = 0; index < count; ++index) seen[index] = false;
        for (std::size_t rank = 0; rank < count; ++rank) {
            const auto proposer = values[accepter_offset + accepter * count + rank];
            if (proposer < 0 || static_cast<std::uint64_t>(proposer) >= count || seen[proposer]) return -2;
            seen[proposer] = true;
            ranks[accepter][proposer] = static_cast<std::int64_t>(rank);
        }
    }
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;

    std::int64_t matched_proposer[5];
    std::int64_t matched_accepter[5];
    std::size_t next_choice[5]{};
    for (std::size_t index = 0; index < count; ++index) {
        matched_proposer[index] = -1;
        matched_accepter[index] = -1;
    }
    for (;;) {
        std::size_t proposer = 0;
        while (proposer < count && matched_accepter[proposer] != -1) ++proposer;
        if (proposer == count) break;
        const auto preference_index = 1 + proposer * count + next_choice[proposer]++;
        const auto accepter = static_cast<std::size_t>(values[preference_index]);
        const auto current = matched_proposer[accepter];
        if (current == -1 || ranks[accepter][proposer] < ranks[accepter][static_cast<std::size_t>(current)]) {
            if (current != -1) matched_accepter[static_cast<std::size_t>(current)] = -1;
            matched_proposer[accepter] = static_cast<std::int64_t>(proposer);
            matched_accepter[proposer] = static_cast<std::int64_t>(accepter);
        }
    }
    for (std::size_t proposer = 0; proposer < count; ++proposer)
        output[proposer] = static_cast<std::uint8_t>(matched_accepter[proposer]);
    return static_cast<std::int64_t>(count);
}
