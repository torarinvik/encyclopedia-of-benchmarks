module apostolico_crochemore_search;

const ACS_MAX_TEXT_LENGTH = 4096;
const ACS_MAX_PATTERN_LENGTH = 128;
const ACS_MAX_PARSEABLE_LENGTH = 4227;
const ACS_PATTERN_STORAGE = ACS_MAX_PATTERN_LENGTH + 1;

fn void acs_preprocess(long* pattern, usz pattern_length, long* kmp_next) {
    long i = 0;
    long j = -1;
    kmp_next[0] = -1;
    while ((usz)i < pattern_length) {
        while (j > -1 && pattern[i] != pattern[j]) j = kmp_next[j];
        i += 1;
        j += 1;
        if (pattern[i] == pattern[j]) kmp_next[i] = kmp_next[j];
        else kmp_next[i] = j;
    }
}

fn long apostolico_crochemore_search(long* input, usz length)
    @export("apostolico_crochemore_search") {
    if (input == null || length < 2 || length > ACS_MAX_PARSEABLE_LENGTH) {
        return -1;
    }

    long text_length_value = input[0];
    long pattern_length_value = input[1];
    if (text_length_value < 0 || text_length_value > ACS_MAX_TEXT_LENGTH
        || pattern_length_value < 1
        || pattern_length_value > ACS_MAX_PATTERN_LENGTH) {
        return -1;
    }
    usz text_length = (usz)text_length_value;
    usz pattern_length = (usz)pattern_length_value;
    if (length != 2 + text_length + pattern_length) return -1;

    usz pattern_start = 2 + text_length;
    long[ACS_PATTERN_STORAGE] pattern = {0};
    for (usz index = 0; index < text_length; index += 1) {
        if (input[2 + index] < 0 || input[2 + index] > 3) return -1;
    }
    for (usz index = 0; index < pattern_length; index += 1) {
        long byte = input[pattern_start + index];
        if (byte < 0 || byte > 3) return -1;
        pattern[index] = byte;
    }
    pattern[pattern_length] = 4;

    long[ACS_PATTERN_STORAGE] kmp_next = {0};
    acs_preprocess(&pattern[0], pattern_length, &kmp_next[0]);

    long ell = 1;
    while ((usz)ell < pattern_length && pattern[ell - 1] == pattern[ell]) {
        ell += 1;
    }
    if ((usz)ell == pattern_length) ell = 0;

    long match_count = 0;
    long sum_offsets = 0;
    long xor_offsets = 0;
    if (text_length >= pattern_length) {
        long i = ell;
        long j = 0;
        long k = 0;
        while ((usz)j <= text_length - pattern_length) {
            while ((usz)i < pattern_length
                   && pattern[i] == input[2 + (usz)j + (usz)i]) {
                i += 1;
            }
            if ((usz)i >= pattern_length) {
                while ((usz)k < (usz)ell
                       && pattern[k] == input[2 + (usz)j + (usz)k]) {
                    k += 1;
                }
                if (k >= ell) {
                    match_count += 1;
                    sum_offsets += j;
                    xor_offsets ^= j;
                }
            }

            j += i - kmp_next[i];
            if (i == ell) {
                if (k > 0) k -= 1;
            } else if (kmp_next[i] <= ell) {
                k = kmp_next[i] > 0 ? kmp_next[i] : 0;
                i = ell;
            } else {
                k = ell;
                i = kmp_next[i];
            }
        }
    }

    return (match_count << 36) | (sum_offsets << 12) | xor_offsets;
}
