module ekg_sequence;

const long MAX_N = 8;
const usz MAX_TERMS = 8;
const usz MAX_CANDIDATE = 40320;
const usz MAX_PARSEABLE_LENGTH = 2;

fn long gcd_i64(long left, long right) {
    while right != 0 {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long ekg_sequence(long* input, usz length, char* output, usz output_capacity)
    @export("ekg_sequence") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long requested = input[0];
    if (length != 1 || requested < 1 || requested > MAX_N) return -1;

    long[MAX_TERMS] terms = zeroed;
    u8[MAX_CANDIDATE + 1] used = zeroed;
    terms[0] = 1;
    used[1] = 1;
    usz term_count = 1;
    if (requested >= 2) {
        terms[1] = 2;
        used[2] = 1;
        term_count = 2;
    }

    while term_count < requested.usz() {
        long position = (long)term_count + 1;
        long previous = terms[term_count - 1];
        long search_bound = previous * position;
        long candidate = 1;
        while candidate <= search_bound {
            if used[candidate.usz()] == 0 && gcd_i64(previous, candidate) > 1: break;
            candidate++;
        }
        if candidate > search_bound: return -1;
        terms[term_count] = candidate;
        term_count++;
        used[candidate.usz()] = 1;
    }

    usz output_bytes = requested.usz() * 8;
    if output == null || output_capacity < output_bytes: return -2;
    for (usz index = 0; index < term_count; index++)
        store_i64_le(output, index * 8, terms[index]);
    return (long)output_bytes;
}
