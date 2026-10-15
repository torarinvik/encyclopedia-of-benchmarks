module max_non_adjacent_sum;

const long INVALID_RESULT = (-9223372036854775807L - 1L);

fn long max_non_adjacent_sum(long* values, usz length) @export("max_non_adjacent_sum") {
    if (values == null || length < 1 || length > 100000) return INVALID_RESULT;
    long two_back = 0, one_back = 0;
    for (usz i = 0; i < length; i++) {
        long value = values[i];
        if (value < 0 || value > 10000) return INVALID_RESULT;
        long take = two_back + value;
        long current = take > one_back ? take : one_back;
        two_back = one_back;
        one_back = current;
    }
    return one_back;
}
