module approximate_tandem_k_edit_repeats;

const int MAX_TEXT = 12;
const int MAX_INPUT = 14;
const usz MAX_OUTPUT = 1592;

fn usz minimum(usz a, usz b) { return a < b ? a : b; }
fn usz edit_distance(long *text, usz a, usz a_len, usz b, usz b_len) {
    usz[MAX_TEXT + 1] row;
    for (usz j = 0; j <= b_len; j++) row[j] = j;
    for (usz i = 1; i <= a_len; i++) {
        usz diagonal = row[0];
        row[0] = i;
        for (usz j = 1; j <= b_len; j++) {
            usz above = row[j];
            usz deletion = above + 1;
            usz insertion = row[j - 1] + 1;
            usz substitution = diagonal + (text[a + i - 1] != text[b + j - 1]);
            row[j] = minimum(minimum(deletion, insertion), substitution);
            diagonal = above;
        }
    }
    return row[b_len];
}
fn usz minimum_edit_cost(long *text, usz start, usz factor_length) {
    usz best = 1000;
    usz[MAX_TEXT] piece_start;
    usz[MAX_TEXT] piece_length;
    for (usz prefix = 0; prefix <= factor_length; prefix++) {
        for (usz suffix = 0; prefix + suffix <= factor_length; suffix++) {
            usz middle = factor_length - prefix - suffix;
            if (middle < 2) continue;
            uint32 end_mask = (uint32)1 << (middle - 1);
            for (uint32 mask = 1; mask < end_mask; mask++) {
                usz segments = 0, previous = 0;
                for (usz cut = 1; cut < middle; cut++) {
                    if ((mask & ((uint32)1 << (cut - 1))) != 0) {
                        piece_start[segments] = start + prefix + previous;
                        piece_length[segments++] = cut - previous;
                        previous = cut;
                    }
                }
                piece_start[segments] = start + prefix + previous;
                piece_length[segments++] = middle - previous;
                usz left = 1000, right = 1000, internal = 0;
                for (usz fragment = 0; fragment <= piece_length[0]; fragment++) {
                    usz cost = edit_distance(text, start, prefix,
                        piece_start[0] + piece_length[0] - fragment, fragment);
                    if (cost < left) left = cost;
                }
                usz last = segments - 1;
                for (usz fragment = 0; fragment <= piece_length[last]; fragment++) {
                    usz cost = edit_distance(text, piece_start[last], fragment,
                        start + factor_length - suffix, suffix);
                    if (cost < right) right = cost;
                }
                for (usz i = 0; i + 1 < segments; i++)
                    internal += edit_distance(text, piece_start[i], piece_length[i],
                                              piece_start[i + 1], piece_length[i + 1]);
                usz total = left + internal + right;
                if (total < best) best = total;
            }
        }
    }
    return best;
}
fn usz count_records(long *text, usz n, usz budget) {
    usz count = 0;
    for (usz start = 0; start < n; start++)
        for (usz factor_length = 2; factor_length <= n - start; factor_length++)
            if (minimum_edit_cost(text, start, factor_length) <= budget) count++;
    return count;
}
fn void store_i64_le(uint8 *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255ul); bits >>= 8; }
}

fn long approximate_tandem_k_edit_repeats(long *input, usz length, uint8 *output, usz capacity)
    @export("approximate_tandem_k_edit_repeats") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n0 = input[0], budget0 = input[1];
    if (n0 < 2 || n0 > MAX_TEXT || budget0 < 0 || budget0 > 4 || length != (usz)n0 + 2) return -1;
    usz n = (usz)n0, budget = (usz)budget0;
    long *text = input + 2;
    for (usz i = 0; i < n; i++) if (text[i] < 0 || text[i] > 3) return -1;
    usz count = count_records(text, n, budget);
    usz bytes = 8 * (1 + 3 * count);
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null || capacity < bytes) return -2;
    store_i64_le(output, 0, (long)count);
    usz record = 0;
    for (usz start = 0; start < n; start++)
        for (usz factor_length = 2; factor_length <= n - start; factor_length++) {
            usz cost = minimum_edit_cost(text, start, factor_length);
            if (cost <= budget) {
                usz offset = 8 * (1 + 3 * record++);
                store_i64_le(output, offset, (long)start);
                store_i64_le(output, offset + 8, (long)factor_length);
                store_i64_le(output, offset + 16, (long)cost);
            }
        }
    return (long)bytes;
}
