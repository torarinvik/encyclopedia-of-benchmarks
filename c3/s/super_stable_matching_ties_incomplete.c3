module super_stable_matching_ties_incomplete;

const long MAX_N = 4;
const usz MAX_PARSEABLE_LENGTH = 34;

fn long solve(long* input, usz length) {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n = input[0];
    if (n < 1 || n > MAX_N) return -1;
    usz side = (usz)(n * n);
    if (length != 1 + 2 * side) return -1;

    long[16] men_rank = zeroed;
    long[16] women_rank = zeroed;
    for (long man = 0; man < n; man++) {
        for (long woman = 0; woman < n; woman++) {
            long rank = input[1 + (usz)(man * n + woman)];
            if (rank < 0 || rank > n) return -1;
            men_rank[man * MAX_N + woman] = rank;
        }
    }
    for (long woman = 0; woman < n; woman++) {
        for (long man = 0; man < n; man++) {
            long rank = input[1 + side + (usz)(woman * n + man)];
            long men_value = men_rank[man * MAX_N + woman];
            if (rank < 0 || rank > n || ((rank > 0) != (men_value > 0))) return -1;
            women_rank[woman * MAX_N + man] = rank;
        }
    }
    for (long person = 0; person < n; person++) {
        long maximum = 0;
        for (long partner = 0; partner < n; partner++) {
            long rank = men_rank[person * MAX_N + partner];
            if (rank > maximum) maximum = rank;
        }
        for (long level = 1; level <= maximum; level++) {
            bool found = false;
            for (long partner = 0; partner < n; partner++)
                if (men_rank[person * MAX_N + partner] == level) found = true;
            if (!found) return -1;
        }
        maximum = 0;
        for (long partner = 0; partner < n; partner++) {
            long rank = women_rank[person * MAX_N + partner];
            if (rank > maximum) maximum = rank;
        }
        for (long level = 1; level <= maximum; level++) {
            bool found = false;
            for (long partner = 0; partner < n; partner++)
                if (women_rank[person * MAX_N + partner] == level) found = true;
            if (!found) return -1;
        }
    }

    bool[16] alive = zeroed;
    bool[16] engaged = zeroed;
    bool[4] proposed = zeroed;
    for (long man = 0; man < n; man++)
        for (long woman = 0; woman < n; woman++)
            alive[man * MAX_N + woman] = men_rank[man * MAX_N + woman] > 0;

    while (true) {
        long proposer = -1;
        for (long man = 0; man < n && proposer < 0; man++) {
            bool has_engagement = false;
            bool has_choice = false;
            for (long woman = 0; woman < n; woman++) {
                long index = man * MAX_N + woman;
                if (engaged[index]) has_engagement = true;
                if (alive[index]) has_choice = true;
            }
            if (!has_engagement && has_choice) proposer = man;
        }
        if (proposer < 0) break;
        long head_rank = n + 1;
        for (long woman = 0; woman < n; woman++) {
            long index = proposer * MAX_N + woman;
            if (alive[index] && men_rank[index] < head_rank)
                head_rank = men_rank[index];
        }
        for (long woman = 0; woman < n; woman++) {
            long index = proposer * MAX_N + woman;
            if (!alive[index] || men_rank[index] != head_rank) continue;
            proposed[woman] = true;
            engaged[index] = true;
            for (long successor = 0; successor < n; successor++) {
                long successor_index = successor * MAX_N + woman;
                if (alive[successor_index]
                    && women_rank[woman * MAX_N + successor] > women_rank[woman * MAX_N + proposer]) {
                    engaged[successor_index] = false;
                    alive[successor_index] = false;
                }
            }
        }
        for (long woman = 0; woman < n; woman++) {
            long count = 0;
            long tail_rank = 0;
            for (long man = 0; man < n; man++) {
                long index = man * MAX_N + woman;
                if (engaged[index]) count++;
                long rank = women_rank[woman * MAX_N + man];
                if (alive[index] && rank > tail_rank) tail_rank = rank;
            }
            if (count > 1) {
                for (long man = 0; man < n; man++) {
                    long index = man * MAX_N + woman;
                    engaged[index] = false;
                    if (alive[index] && women_rank[woman * MAX_N + man] == tail_rank)
                        alive[index] = false;
                }
            }
        }
    }

    long base = n + 1;
    long limit = 1;
    for (long i = 0; i < n; i++) limit *= base;
    long best_code = 0;
    long best_size = -1;
    for (long code = 0; code < limit; code++) {
        long used = 0;
        long size = 0;
        bool valid = true;
        long place = limit / base;
        for (long man = 0; man < n; man++) {
            long woman = (code / place) % base;
            if (woman < n) {
                long index = man * MAX_N + woman;
                if (!engaged[index] || (used & (1 << woman)) != 0) valid = false;
                used |= 1 << woman;
                size++;
            }
            if (man + 1 < n) place /= base;
        }
        if (valid && size > best_size) {
            best_size = size;
            best_code = code;
        }
    }
    bool[4] matched_woman = zeroed;
    long place = limit / base;
    for (long man = 0; man < n; man++) {
        long woman = (best_code / place) % base;
        if (woman < n) matched_woman[woman] = true;
        if (man + 1 < n) place /= base;
    }
    for (long woman = 0; woman < n; woman++)
        if (proposed[woman] && !matched_woman[woman]) return -2;
    return best_code;
}

fn long super_stable_matching_ties_incomplete(long* input, usz length)
        @export("super_stable_matching_ties_incomplete") {
    return solve(input, length);
}
