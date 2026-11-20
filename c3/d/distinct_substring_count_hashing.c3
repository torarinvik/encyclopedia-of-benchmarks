module distinct_substring_count_hashing;

const long MAX_TEXT = 64;
const long HASH_MODULUS = 1000000007;
const usz HASH_SLOTS = 64;

fn long distinct_substring_count_hashing(long* input, usz length) @export("distinct_substring_count_hashing") {
    if (input == null || length < 1 || length > 66) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > MAX_TEXT || length != (usz)(n_value + 1)) return -1;
    usz n = (usz)n_value;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;

    long[65] prefix = zeroed, powers = zeroed;
    powers[0] = 1;
    for (usz i = 0; i < n; i++) {
        prefix[i + 1] = (prefix[i] * 257 + input[i + 1] + 1) % HASH_MODULUS;
        powers[i + 1] = powers[i] * 257 % HASH_MODULUS;
    }
    long[64] group_hash, group_head, representative_start, representative_next;
    long distinct = 0;
    for (usz width = 1; width <= n; width++) {
        for (usz slot = 0; slot < HASH_SLOTS; slot++) { group_hash[slot] = -1; group_head[slot] = -1; }
        usz representative_count = 0;
        for (usz start = 0; start + width <= n; start++) {
            usz end = start + width;
            long fingerprint = (prefix[end] - prefix[start] * powers[width] % HASH_MODULUS) % HASH_MODULUS;
            if (fingerprint < 0) fingerprint += HASH_MODULUS;
            usz slot = (usz)(fingerprint % (long)HASH_SLOTS);
            while (group_hash[slot] != -1 && group_hash[slot] != fingerprint) slot = (slot + 1) % HASH_SLOTS;
            if (group_hash[slot] == -1) group_hash[slot] = fingerprint;
            bool duplicate = false;
            long prior = group_head[slot];
            while (prior >= 0) {
                usz old_start = (usz)representative_start[(usz)prior];
                usz offset = 0;
                while (offset < width && input[start + offset + 1] == input[old_start + offset + 1]) offset++;
                if (offset == width) { duplicate = true; break; }
                prior = representative_next[(usz)prior];
            }
            if (!duplicate) {
                representative_start[representative_count] = (long)start;
                representative_next[representative_count] = group_head[slot];
                group_head[slot] = (long)representative_count++;
                distinct++;
            }
        }
    }
    return distinct;
}
