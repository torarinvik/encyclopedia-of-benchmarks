#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define SR_MAX_PARTICIPANTS 8
#define SR_MAX_PARSEABLE_LENGTH 58
#define SR_CYCLE_STORAGE (2 * SR_MAX_PARTICIPANTS + 2)

static bool sr_singleton_lists_are_reciprocal(
    size_t n, const int64_t preference[SR_MAX_PARTICIPANTS][SR_MAX_PARTICIPANTS],
    const int64_t left[SR_MAX_PARTICIPANTS],
    const int64_t right[SR_MAX_PARTICIPANTS]) {
    for (size_t person = 0; person < n; ++person) {
        if (left[person] != right[person]) return false;
        const int64_t partner = preference[person][left[person]];
        if (partner == (int64_t)person
            || preference[partner][left[partner]] != (int64_t)person) {
            return false;
        }
    }
    return true;
}

int64_t stable_roommates(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > SR_MAX_PARSEABLE_LENGTH) {
        return -1;
    }
    const int64_t n_value = input[0];
    if (n_value < 2 || n_value > SR_MAX_PARTICIPANTS || (n_value & 1) != 0) {
        return -1;
    }
    const size_t n = (size_t)n_value;
    if (length != 1 + n * (n - 1)) return -1;

    int64_t preference[SR_MAX_PARTICIPANTS][SR_MAX_PARTICIPANTS] = {{0}};
    int64_t rank[SR_MAX_PARTICIPANTS][SR_MAX_PARTICIPANTS] = {{0}};
    size_t cursor = 1;
    for (size_t person = 0; person < n; ++person) {
        bool seen[SR_MAX_PARTICIPANTS] = {false};
        for (size_t position = 0; position < n - 1; ++position) {
            const int64_t other = input[cursor++];
            if (other < 0 || other >= n_value || other == (int64_t)person
                || seen[other]) {
                return -1;
            }
            seen[other] = true;
            preference[person][position] = other;
            rank[person][other] = (int64_t)position;
        }
        preference[person][n - 1] = (int64_t)person;
        rank[person][person] = (int64_t)(n - 1);
    }

    int64_t left[SR_MAX_PARTICIPANTS] = {0};
    int64_t right[SR_MAX_PARTICIPANTS] = {0};
    for (size_t person = 0; person < n; ++person) right[person] = (int64_t)(n - 1);

    bool proposed_to[SR_MAX_PARTICIPANTS] = {false};
    int64_t proposer = 0;
    int64_t choice = 0;
    for (size_t person = 0; person < n; ++person) {
        proposer = (int64_t)person;
        for (;;) {
            choice = preference[proposer][left[proposer]];
            if (choice == proposer) return 0;
            int64_t current = preference[choice][right[choice]];
            while (rank[choice][proposer] > rank[choice][current]) {
                ++left[proposer];
                if ((size_t)left[proposer] >= n) return 0;
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
    for (size_t person = 0; person < n; ++person) {
        if (left[person] > right[person]) possible = false;
    }
    if (!possible) return 0;

    int64_t second[SR_MAX_PARTICIPANTS];
    for (size_t person = 0; person < n; ++person) second[person] = left[person] + 1;
    size_t first_unmatched = 0;
    size_t first_in_cycle = 0;
    bool tail[SR_MAX_PARTICIPANTS] = {false};
    int64_t cycle[SR_CYCLE_STORAGE] = {0};

    for (;;) {
        while (first_unmatched < n
               && left[first_unmatched] == right[first_unmatched]) {
            ++first_unmatched;
        }
        if (first_unmatched == n) {
            return sr_singleton_lists_are_reciprocal(n, preference, left, right)
                ? 1 : 0;
        }

        int64_t person;
        size_t position;
        bool cycle_set[SR_MAX_PARTICIPANTS] = {false};
        if (first_in_cycle > 0) {
            person = cycle[first_in_cycle - 1];
            position = first_in_cycle - 1;
            for (size_t id = 0; id < n; ++id) cycle_set[id] = tail[id];
        } else {
            person = (int64_t)first_unmatched;
            position = 0;
        }

        for (;;) {
            cycle_set[person] = true;
            if (position >= SR_CYCLE_STORAGE) return 0;
            cycle[position++] = person;

            int64_t list_position = second[person];
            int64_t next_choice = -1;
            bool found_choice = false;
            while ((size_t)list_position < n) {
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

        const size_t last_in_cycle = position - 1;
        for (size_t id = 0; id < n; ++id) tail[id] = cycle_set[id];
        size_t cycle_position = position;
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

        for (size_t cycle_index = first_in_cycle;
             cycle_index <= last_in_cycle; ++cycle_index) {
            proposer = cycle[cycle_index];
            left[proposer] = second[proposer];
            second[proposer] = left[proposer] + 1;
            choice = preference[proposer][left[proposer]];
            right[choice] = rank[choice][proposer];
        }
        for (size_t cycle_index = first_in_cycle;
             cycle_index <= last_in_cycle; ++cycle_index) {
            if (left[cycle[cycle_index]] > right[cycle[cycle_index]]) return 0;
        }
    }
}
