module yellowstone_permutation_prefix;

const long MAX_N = 64;
const long MIN_CAP = 3;
const long MAX_CAP = 256;
const usz MAX_PARSEABLE_LENGTH = 3;

fn long ypp_gcd(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long ypp_construct(long requested, long candidate_cap) {
    long[64] terms = {};
    bool[257] used = {};
    terms[0] = 1;
    terms[1] = 2;
    terms[2] = 3;
    if (requested <= 3) return terms[(usz)requested - 1];
    used[1] = true;
    used[2] = true;
    used[3] = true;

    usz term_count = 3;
    while (term_count < (usz)requested) {
        long two_back = terms[term_count - 2];
        long previous = terms[term_count - 1];
        long candidate = 1;
        while (candidate <= candidate_cap) {
            if (!used[(usz)candidate]
                    && ypp_gcd(candidate, two_back) > 1
                    && ypp_gcd(candidate, previous) == 1) break;
            candidate += 1;
        }
        if (candidate > candidate_cap) return -1;
        terms[term_count] = candidate;
        term_count += 1;
        used[(usz)candidate] = true;
    }
    return terms[(usz)requested - 1];
}

fn long yellowstone_permutation_prefix(long* input, usz length) @export("yellowstone_permutation_prefix") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (length != 2) return -1;
    long requested = input[0];
    long candidate_cap = input[1];
    if (requested < 1 || requested > MAX_N
            || candidate_cap < MIN_CAP || candidate_cap > MAX_CAP) return -1;
    return ypp_construct(requested, candidate_cap);
}
