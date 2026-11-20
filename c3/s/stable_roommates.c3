module stable_roommates;

const SR_MAX_PARTICIPANTS = 8;
const SR_MAX_PARSEABLE_LENGTH = 58;
const SR_CYCLE_STORAGE = 2 * SR_MAX_PARTICIPANTS + 2;

fn long stable_roommates(long* input, usz length)
    @export("stable_roommates") {
    if (input == null || length < 1 || length > SR_MAX_PARSEABLE_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 2 || n_value > SR_MAX_PARTICIPANTS || (n_value & 1) != 0) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n * (n - 1)) return -1;

    long[SR_MAX_PARTICIPANTS][SR_MAX_PARTICIPANTS] preference = zeroed;
    long[SR_MAX_PARTICIPANTS][SR_MAX_PARTICIPANTS] rank = zeroed;
    usz cursor = 1;
    for (usz person = 0; person < n; person += 1) {
        bool[SR_MAX_PARTICIPANTS] seen = zeroed;
        for (usz position = 0; position < n - 1; position += 1) {
            long other = input[cursor];
            cursor += 1;
            if (other < 0 || other >= n_value || other == (long)person || seen[(usz)other]) return -1;
            seen[(usz)other] = true;
            preference[person][position] = other;
            rank[person][(usz)other] = (long)position;
        }
        preference[person][n - 1] = (long)person;
        rank[person][person] = (long)(n - 1);
    }

    long[SR_MAX_PARTICIPANTS] left = zeroed;
    long[SR_MAX_PARTICIPANTS] right = zeroed;
    for (usz person = 0; person < n; person += 1) right[person] = (long)(n - 1);

    bool[SR_MAX_PARTICIPANTS] proposed_to = zeroed;
    long proposer = 0;
    long choice = 0;
    for (usz person = 0; person < n; person += 1) {
        proposer = (long)person;
        while (true) {
            choice = preference[(usz)proposer][(usz)left[(usz)proposer]];
            if (choice == proposer) return 0;
            long current = preference[(usz)choice][(usz)right[(usz)choice]];
            while (rank[(usz)choice][(usz)proposer] > rank[(usz)choice][(usz)current]) {
                left[(usz)proposer] += 1;
                if ((usz)left[(usz)proposer] >= n) return 0;
                choice = preference[(usz)proposer][(usz)left[(usz)proposer]];
                if (choice == proposer) return 0;
                current = preference[(usz)choice][(usz)right[(usz)choice]];
            }
            right[(usz)choice] = rank[(usz)choice][(usz)proposer];
            proposer = current;
            if (!proposed_to[(usz)choice]) break;
        }
        proposed_to[(usz)choice] = true;
    }
    bool possible = proposer == choice;
    for (usz person = 0; person < n; person += 1) {
        if (left[person] > right[person]) possible = false;
    }
    if (!possible) return 0;

    long[SR_MAX_PARTICIPANTS] second;
    for (usz person = 0; person < n; person += 1) second[person] = left[person] + 1;
    usz first_unmatched = 0;
    usz first_in_cycle = 0;
    bool[SR_MAX_PARTICIPANTS] tail = zeroed;
    long[SR_CYCLE_STORAGE] cycle = zeroed;

    while (true) {
        while (first_unmatched < n && left[first_unmatched] == right[first_unmatched]) {
            first_unmatched += 1;
        }
        if (first_unmatched == n) {
            for (usz person = 0; person < n; person += 1) {
                if (left[person] != right[person]) return 0;
                long partner = preference[person][(usz)left[person]];
                if (partner == (long)person
                    || preference[(usz)partner][(usz)left[(usz)partner]] != (long)person) return 0;
            }
            return 1;
        }

        long person;
        usz position;
        bool[SR_MAX_PARTICIPANTS] cycle_set = zeroed;
        if (first_in_cycle > 0) {
            person = cycle[first_in_cycle - 1];
            position = first_in_cycle - 1;
            for (usz id = 0; id < n; id += 1) cycle_set[id] = tail[id];
        } else {
            person = (long)first_unmatched;
            position = 0;
        }

        while (true) {
            cycle_set[(usz)person] = true;
            if (position >= SR_CYCLE_STORAGE) return 0;
            cycle[position] = person;
            position += 1;

            long list_position = second[(usz)person];
            long next_choice = -1;
            bool found_choice = false;
            while ((usz)list_position < n) {
                next_choice = preference[(usz)person][(usz)list_position];
                list_position += 1;
                if (next_choice == person) return 0;
                if (rank[(usz)next_choice][(usz)person] <= right[(usz)next_choice]) {
                    found_choice = true;
                    break;
                }
            }
            if (!found_choice) return 0;
            second[(usz)person] = list_position - 1;
            person = preference[(usz)next_choice][(usz)right[(usz)next_choice]];
            if (cycle_set[(usz)person]) break;
        }

        usz last_in_cycle = position - 1;
        for (usz id = 0; id < n; id += 1) tail[id] = cycle_set[id];
        usz cycle_position = position;
        bool found_cycle_start = false;
        while (cycle_position > 0) {
            cycle_position -= 1;
            tail[(usz)cycle[cycle_position]] = false;
            if (cycle[cycle_position] == person) {
                found_cycle_start = true;
                break;
            }
        }
        if (!found_cycle_start) return 0;
        first_in_cycle = cycle_position;

        usz cycle_index = first_in_cycle;
        while (cycle_index <= last_in_cycle) {
            proposer = cycle[cycle_index];
            left[(usz)proposer] = second[(usz)proposer];
            second[(usz)proposer] = left[(usz)proposer] + 1;
            choice = preference[(usz)proposer][(usz)left[(usz)proposer]];
            right[(usz)choice] = rank[(usz)choice][(usz)proposer];
            cycle_index += 1;
        }
        cycle_index = first_in_cycle;
        while (cycle_index <= last_in_cycle) {
            if (left[(usz)cycle[cycle_index]] > right[(usz)cycle[cycle_index]]) return 0;
            cycle_index += 1;
        }
    }
}
