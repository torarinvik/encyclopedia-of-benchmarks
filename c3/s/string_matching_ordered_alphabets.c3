module string_matching_ordered_alphabets;

const usz MAX_TEXT = 4096;
const usz MAX_PATTERN = 128;
const usz MAX_INPUT = 4227;

fn void advance_maximal_suffix(long* segment, int length, int* left, int* right,
                               int* offset, int* period) {
    while (*right + *offset < length) {
        long a = segment[*left + *offset];
        long b = segment[*right + *offset];
        if (a == b) {
            if (*offset == *period) {
                *right += *period;
                *offset = 1;
            } else {
                *offset += 1;
            }
        } else if (a > b) {
            *right += *offset;
            *offset = 1;
            *period = *right - *left;
        } else {
            *left = *right;
            *right += 1;
            *offset = 1;
            *period = 1;
        }
    }
}

fn bool prefix_repeats(long* segment, int shift, int last_index) {
    for (int q = 0; q <= last_index; q++)
        if (segment[q] != segment[shift + q]) return false;
    return true;
}

fn long string_matching_ordered_alphabets(long* input, usz length) @export("string_matching_ordered_alphabets") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > (long)MAX_TEXT || m64 < 1 || m64 > (long)MAX_PATTERN) return -1;
    int n = (int)n64, m = (int)m64;
    if (length != 2 + (usz)n + (usz)m) return -1;
    usz pattern_start = 2 + (usz)n;
    for (int q = 0; q < n; q++)
        if (input[2 + (usz)q] < 0 || input[2 + (usz)q] > 3) return -1;
    for (int q = 0; q < m; q++)
        if (input[pattern_start + (usz)q] < 0 || input[pattern_start + (usz)q] > 3) return -1;
    if (n < m) return 0;

    int alignment = 0, matched = 0;
    int suffix_left = -1, suffix_right = 0, suffix_offset = 1, period = 1;
    long count = 0, offset_sum = 0, offset_xor = 0;
    while (alignment <= n - m) {
        while (alignment + matched < n && matched < m &&
               input[pattern_start + (usz)matched] == input[2 + (usz)(alignment + matched)]) matched++;
        if (matched == 0) {
            alignment++;
            suffix_left = -1; suffix_right = 0; suffix_offset = period = 1;
            continue;
        }
        if (matched == m) {
            count++;
            offset_sum += (long)alignment;
            offset_xor ^= (long)alignment;
            if (alignment == n - m) break;
        }

        long* segment = input + 2 + (usz)alignment;
        advance_maximal_suffix(segment, matched + 1,
                               &suffix_left, &suffix_right, &suffix_offset, &period);
        bool reusable = suffix_left < 0 ||
            (suffix_left < period && prefix_repeats(segment, period, suffix_left));
        if (reusable) {
            alignment += period;
            matched -= period;
            if (matched < 0) matched = 0;
            if (suffix_right - suffix_left > period) suffix_right -= period;
            else { suffix_left = -1; suffix_right = 0; suffix_offset = period = 1; }
        } else {
            int conservative = matched - suffix_left - 1 < suffix_right + 1
                ? matched - suffix_left - 1 : suffix_right + 1;
            int certified = suffix_left + 1 > conservative ? suffix_left + 1 : conservative;
            alignment += certified + 1;
            matched = 0;
            suffix_left = -1; suffix_right = 0; suffix_offset = period = 1;
        }
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}
