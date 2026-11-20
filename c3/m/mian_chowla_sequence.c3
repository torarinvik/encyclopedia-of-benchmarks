module mian_chowla_sequence;

const long MAX_N = 30;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long mian_chowla_sequence(long* input, usz length) @export("mian_chowla_sequence") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long requested = input[0];
    if (length != 1 || requested < 1 || requested > MAX_N) return -1;

    long[30] terms = {};
    long[465] used_sums = {};
    usz term_count = 1;
    usz sum_count = 1;
    terms[0] = 1;
    used_sums[0] = 2;

    while (term_count < (usz)requested) {
        long candidate = terms[term_count - 1] + 1;
        for (;;) {
            bool valid = true;
            for (usz term = 0; term < term_count && valid; term += 1) {
                long sum = candidate + terms[term];
                for (usz old = 0; old < sum_count; old += 1) {
                    if (used_sums[old] == sum) { valid = false; break; }
                }
            }
            if (valid) {
                long doubled = 2 * candidate;
                for (usz old = 0; old < sum_count; old += 1) {
                    if (used_sums[old] == doubled) { valid = false; break; }
                }
            }
            if (valid) break;
            candidate += 1;
        }

        for (usz term = 0; term < term_count; term += 1) {
            used_sums[sum_count] = candidate + terms[term];
            sum_count += 1;
        }
        used_sums[sum_count] = 2 * candidate;
        sum_count += 1;
        terms[term_count] = candidate;
        term_count += 1;
    }
    return terms[(usz)requested - 1];
}
