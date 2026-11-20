const long MAX_INDEX = 64;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long klarner_rado_affine_closure_sequence(long* input, usz length) @export("klarner_rado_affine_closure_sequence") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long requested = input[0];
    if (length != 1 || requested < 1 || requested > MAX_INDEX) return -1;

    long[64] terms = {};
    terms[0] = 1;
    usz count = 1;
    usz twice = 0;
    usz thrice_plus_two = 0;
    usz sixfold_plus_three = 0;
    while (count < (usz)requested) {
        long by_two = 2 * terms[twice];
        long by_three = 3 * terms[thrice_plus_two] + 2;
        long by_six = 6 * terms[sixfold_plus_three] + 3;
        long next = by_two;
        if (by_three < next) next = by_three;
        if (by_six < next) next = by_six;
        terms[count] = next;
        count += 1;
        if (by_two == next) twice += 1;
        if (by_three == next) thrice_plus_two += 1;
        if (by_six == next) sixfold_plus_three += 1;
    }
    return terms[(usz)requested - 1];
}
