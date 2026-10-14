module rabin_karp;

const long BASE = 256;
const long MODULUS = 1000003;

// Test ASCII pattern presence with a Rabin-Karp rolling hash.
fn long rabin_karp(long* values, usz length) @export("rabin_karp")
{
    if (values == null || length < 2 || length > 512) return -1;
    long text_length_value = values[0];
    long pattern_length_value = values[1];
    if (text_length_value < 0 || text_length_value > 255 ||
        pattern_length_value < 0 || pattern_length_value > 255 ||
        length != (usz)(2 + text_length_value + pattern_length_value)) return -1;
    for (usz index = 0; index < (usz)(text_length_value + pattern_length_value); index++) {
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;
    }

    usz text_length = (usz)text_length_value;
    usz pattern_length = (usz)pattern_length_value;
    if (pattern_length == 0) return 1;
    if (pattern_length > text_length) return 0;

    long pattern_hash = 0;
    long rolling_hash = 0;
    long high_power = 1;
    for (usz index = 0; index < pattern_length; index++) {
        pattern_hash = (pattern_hash * BASE + values[2 + text_length + index]) % MODULUS;
        rolling_hash = (rolling_hash * BASE + values[2 + index]) % MODULUS;
        if (index + 1 < pattern_length) high_power = (high_power * BASE) % MODULUS;
    }
    usz last_start = text_length - pattern_length;
    for (usz start = 0; start <= last_start; start++) {
        if (rolling_hash == pattern_hash) {
            usz offset = 0;
            while (offset < pattern_length && values[2 + start + offset] == values[2 + text_length + offset]) offset++;
            if (offset == pattern_length) return 1;
        }
        if (start < last_start) {
            long removed = (values[2 + start] * high_power) % MODULUS;
            rolling_hash = (rolling_hash - removed) % MODULUS;
            if (rolling_hash < 0) rolling_hash += MODULUS;
            rolling_hash = (rolling_hash * BASE + values[2 + start + pattern_length]) % MODULUS;
        }
    }
    return 0;
}
