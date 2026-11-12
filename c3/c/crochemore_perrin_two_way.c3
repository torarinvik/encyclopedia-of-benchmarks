module crochemore_perrin_two_way;

const usz MAX_TEXT_LENGTH = 64;
const usz MAX_PATTERN_LENGTH = 32;
const usz MAX_INPUT_LENGTH = 99;

fn void maximal_suffix(long* values, int base, int length, bool reverse_order,
                       int* critical_out, int* period_out) {
    int maximal = -1;
    int candidate = 0;
    int offset = 1;
    int period = 1;
    while (candidate + offset < length) {
        long a = values[base + candidate + offset];
        long b = values[base + maximal + offset];
        bool precedes = reverse_order ? a > b : a < b;
        if (precedes) {
            candidate += offset;
            offset = 1;
            period = candidate - maximal;
        } else if (a == b) {
            if (offset != period) offset++;
            else { candidate += period; offset = 1; }
        } else {
            maximal = candidate;
            candidate = maximal + 1;
            offset = 1;
            period = 1;
        }
    }
    *critical_out = maximal;
    *period_out = period;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long crochemore_perrin_two_way(long* values, usz length, char* output, usz capacity)
        @export("crochemore_perrin_two_way") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 32) return -1;
    int text_length = (int)values[0];
    int pattern_length = (int)values[1];
    if (length != (usz)(2 + text_length + pattern_length)) return -1;
    int text_base = 2;
    int pattern_base = 2 + text_length;
    for (int i = 0; i < text_length; i++)
        if (values[text_base + i] < 0 || values[text_base + i] > 255) return -1;
    for (int i = 0; i < pattern_length; i++)
        if (values[pattern_base + i] < 0 || values[pattern_base + i] > 255) return -1;

    long[MAX_TEXT_LENGTH + 1] matches = zeroed;
    int match_count = 0;
    if (pattern_length == 0) {
        for (int i = 0; i <= text_length; i++) matches[match_count++] = i;
    } else if (pattern_length <= text_length) {
        int critical_a, period_a, critical_b, period_b;
        maximal_suffix(values, pattern_base, pattern_length, false, &critical_a, &period_a);
        maximal_suffix(values, pattern_base, pattern_length, true, &critical_b, &period_b);
        int critical, period;
        if (critical_a > critical_b) { critical = critical_a; period = period_a; }
        else { critical = critical_b; period = period_b; }
        bool periodic = period + critical + 1 <= pattern_length;
        for (int i = 0; periodic && i <= critical; i++)
            if (values[pattern_base + i] != values[pattern_base + i + period]) periodic = false;
        int shift = periodic ? period
            : (critical > pattern_length - critical - 1 ? critical : pattern_length - critical - 1) + 1;
        int memory = -1;
        int start = 0;
        while (start <= text_length - pattern_length) {
            int index = periodic && memory > critical ? memory + 1 : critical + 1;
            while (index < pattern_length
                   && values[pattern_base + index] == values[text_base + start + index]) index++;
            if (index >= pattern_length) {
                index = critical;
                while (index > memory
                       && values[pattern_base + index] == values[text_base + start + index]) index--;
                if (index <= memory) matches[match_count++] = start;
                start += shift;
                memory = periodic ? pattern_length - period - 1 : -1;
            } else {
                start += index - critical;
                memory = -1;
            }
        }
    }

    usz output_bytes = (usz)match_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (int i = 0; i < match_count; i++) store_i64_le(output, (usz)i * 8, matches[i]);
    return (long)output_bytes;
}
