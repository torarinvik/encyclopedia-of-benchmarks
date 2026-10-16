module problem51;

const usz PRIME_LIMIT = 1000000;
const u8 PRIME = 1;
const u8 FILTERED_PRIME = 2;
const u8 FILTERED_CHECKED = 3;
const u8 CHECKED_NONPRIME = 4;
const u8 CHECKED_OTHER_PRIME = 5;

fn usz repeated_extra_digits(long value) {
    usz[10] counts = {0};
    usz length = 0;
    while (value > 0) {
        counts[(usz)(value % 10)]++;
        length++;
        value /= 10;
    }
    usz distinct = 0;
    for (usz digit = 0; digit < 10; digit++) if (counts[digit] != 0) distinct++;
    return length - distinct;
}

fn usz count_digit(long value, long digit) {
    usz count = 0;
    while (value > 0) {
        if (value % 10 == digit) count++;
        value /= 10;
    }
    return count;
}

fn long replace_all(long value, long digit, long replacement) {
    long result = value, place = 1;
    while (value > 0) {
        if (value % 10 == digit) result += (replacement - digit) * place;
        value /= 10;
        place *= 10;
    }
    return result;
}

fn void mark_checked(u8* state, long value) {
    if (state[(usz)value] == FILTERED_PRIME) state[(usz)value] = FILTERED_CHECKED;
    else if (state[(usz)value] == 0) state[(usz)value] = CHECKED_NONPRIME;
    else if (state[(usz)value] == PRIME) state[(usz)value] = CHECKED_OTHER_PRIME;
}

fn long problem51(long ignored) @export("problem51") {
    if (ignored != 0) return -1;
    u8[1000000] state = {0};
    for (usz value = 2; value < PRIME_LIMIT; value++) state[value] = PRIME;
    for (usz prime = 2; prime * prime < PRIME_LIMIT; prime++) {
        if (state[prime] != PRIME) continue;
        for (usz multiple = prime * prime; multiple < PRIME_LIMIT; multiple += prime) state[multiple] = 0;
    }
    for (usz value = 2; value < PRIME_LIMIT; value++) {
        if (state[value] == PRIME && repeated_extra_digits((long)value) >= 3) state[value] = FILTERED_PRIME;
    }
    for (long number = 2; number < (long)PRIME_LIMIT; number++) {
        if (state[(usz)number] != FILTERED_PRIME) continue;
        long place = 1;
        while (number / place >= 10) place *= 10;
        bool[10] seen_digits = {0};
        for (; place > 0; place /= 10) {
            long digit = (number / place) % 10;
            if (seen_digits[(usz)digit] || count_digit(number, digit) < 2) continue;
            seen_digits[(usz)digit] = true;
            usz family_count = 0;
            long family_minimum = 9223372036854775807L;
            for (long replacement = 0; replacement <= 9; replacement++) {
                long member = replace_all(number, digit, replacement);
                mark_checked(&state[0], member);
                if (state[(usz)member] == FILTERED_PRIME || state[(usz)member] == FILTERED_CHECKED) {
                    family_count++;
                    if (member < family_minimum) family_minimum = member;
                }
            }
            if (family_count == 8) return family_minimum;
        }
    }
    return -1;
}
