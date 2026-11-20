#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_participants = 8;
constexpr std::size_t max_parseable_length = 58;
constexpr std::size_t cycle_storage = 2 * max_participants + 2;

bool singleton_lists_are_reciprocal(
    std::size_t n,
    const std::int64_t preference[max_participants][max_participants],
    const std::int64_t left[max_participants],
    const std::int64_t right[max_participants]) noexcept {
    for (std::size_t person = 0; person < n; ++person) {
        if (left[person] != right[person]) return false;
        const std::int64_t partner = preference[person][left[person]];
        if (partner == static_cast<std::int64_t>(person)
            || preference[partner][left[partner]] != static_cast<std::int64_t>(person)) {
            return false;
        }
    }
    return true;
}
} // namespace

extern "C" std::int64_t stable_roommates(const std::int64_t *input,
                                         std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const std::int64_t n_value = input[0];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_participants)
        || (n_value & 1) != 0) {
        return -1;
    }
    const auto n = static_cast<std::size_t>(n_value);
    if (length != 1 + n * (n - 1)) return -1;

    std::int64_t preference[max_participants][max_participants]{};
    std::int64_t rank[max_participants][max_participants]{};
    std::size_t cursor = 1;
    for (std::size_t person = 0; person < n; ++person) {
        bool seen[max_participants]{};
        for (std::size_t position = 0; position < n - 1; ++position) {
            const std::int64_t other = input[cursor++];
            if (other < 0 || other >= n_value
                || other == static_cast<std::int64_t>(person) || seen[other]) {
                return -1;
            }
            seen[other] = true;
            preference[person][position] = other;
            rank[person][other] = static_cast<std::int64_t>(position);
        }
        preference[person][n - 1] = static_cast<std::int64_t>(person);
        rank[person][person] = static_cast<std::int64_t>(n - 1);
    }

    std::int64_t left[max_participants]{};
    std::int64_t right[max_participants]{};
    for (std::size_t person = 0; person < n; ++person) {
        right[person] = static_cast<std::int64_t>(n - 1);
    }

    bool proposed_to[max_participants]{};
    std::int64_t proposer = 0;
    std::int64_t choice = 0;
    for (std::size_t person = 0; person < n; ++person) {
        proposer = static_cast<std::int64_t>(person);
        for (;;) {
            choice = preference[proposer][left[proposer]];
            if (choice == proposer) return 0;
            std::int64_t current = preference[choice][right[choice]];
            while (rank[choice][proposer] > rank[choice][current]) {
                ++left[proposer];
                if (static_cast<std::size_t>(left[proposer]) >= n) return 0;
                choice = preference[proposer][left[proposer]];
                if (choice == proposer) return 0;
                current = preference[choice][right[choice]];
            }
            right[choice] = rank[choice][proposer];
            proposer = current;
            if (!proposed_to[choice]) break;
        }
        proposed_to[choice] = true;
    }
    bool possible = proposer == choice;
    for (std::size_t person = 0; person < n; ++person) {
        if (left[person] > right[person]) possible = false;
    }
    if (!possible) return 0;

    std::int64_t second[max_participants]{};
    for (std::size_t person = 0; person < n; ++person) {
        second[person] = left[person] + 1;
    }
    std::size_t first_unmatched = 0;
    std::size_t first_in_cycle = 0;
    bool tail[max_participants]{};
    std::int64_t cycle[cycle_storage]{};

    for (;;) {
        while (first_unmatched < n
               && left[first_unmatched] == right[first_unmatched]) {
            ++first_unmatched;
        }
        if (first_unmatched == n) {
            return singleton_lists_are_reciprocal(n, preference, left, right) ? 1 : 0;
        }

        std::int64_t person;
        std::size_t position;
        bool cycle_set[max_participants]{};
        if (first_in_cycle > 0) {
            person = cycle[first_in_cycle - 1];
            position = first_in_cycle - 1;
            for (std::size_t id = 0; id < n; ++id) cycle_set[id] = tail[id];
        } else {
            person = static_cast<std::int64_t>(first_unmatched);
            position = 0;
        }

        for (;;) {
            cycle_set[person] = true;
            if (position >= cycle_storage) return 0;
            cycle[position++] = person;

            std::int64_t list_position = second[person];
            std::int64_t next_choice = -1;
            bool found_choice = false;
            while (static_cast<std::size_t>(list_position) < n) {
                next_choice = preference[person][list_position++];
                if (next_choice == person) return 0;
                if (rank[next_choice][person] <= right[next_choice]) {
                    found_choice = true;
                    break;
                }
            }
            if (!found_choice) return 0;
            second[person] = list_position - 1;
            person = preference[next_choice][right[next_choice]];
            if (cycle_set[person]) break;
        }

        const std::size_t last_in_cycle = position - 1;
        for (std::size_t id = 0; id < n; ++id) tail[id] = cycle_set[id];
        std::size_t cycle_position = position;
        bool found_cycle_start = false;
        while (cycle_position > 0) {
            --cycle_position;
            tail[cycle[cycle_position]] = false;
            if (cycle[cycle_position] == person) {
                found_cycle_start = true;
                break;
            }
        }
        if (!found_cycle_start) return 0;
        first_in_cycle = cycle_position;

        for (std::size_t cycle_index = first_in_cycle;
             cycle_index <= last_in_cycle; ++cycle_index) {
            proposer = cycle[cycle_index];
            left[proposer] = second[proposer];
            second[proposer] = left[proposer] + 1;
            choice = preference[proposer][left[proposer]];
            right[choice] = rank[choice][proposer];
        }
        for (std::size_t cycle_index = first_in_cycle;
             cycle_index <= last_in_cycle; ++cycle_index) {
            if (left[cycle[cycle_index]] > right[cycle[cycle_index]]) return 0;
        }
    }
}
