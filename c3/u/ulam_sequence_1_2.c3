module ulam_sequence_1_2;

const long MAX_N = 14;
const long MAX_CANDIDATE = 64;
const usz MAX_SUM = 74;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long ulam_sequence_1_2(long* input, usz length) @export("ulam_sequence_1_2") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long requested = input[0];
    if (length != 1 || requested < 1 || requested > MAX_N) return -1;

    long[14] terms = {};
    long[75] representations = {};
    terms[0] = 1;
    terms[1] = 2;
    representations[3] = 1;
    usz term_count = 2;

    while (term_count < (usz)requested) {
        long candidate = terms[term_count - 1] + 1;
        while (candidate <= MAX_CANDIDATE && representations[(usz)candidate] != 1)
            candidate += 1;
        if (candidate > MAX_CANDIDATE) return -1;
        for (usz old = 0; old < term_count; old += 1) {
            usz sum = (usz)(candidate + terms[old]);
            if (representations[sum] < 2) representations[sum] += 1;
        }
        terms[term_count] = candidate;
        term_count += 1;
    }
    return terms[(usz)requested - 1];
}
