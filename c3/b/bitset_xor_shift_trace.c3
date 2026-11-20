module bitset_xor_shift_trace;

const usz MAX_BITS = 4096;
const usz MAX_WORDS = 64;
const usz MAX_OPERATIONS = 64;

fn uint popcount64(ulong value) {
    uint count = 0;
    while (value != 0) { value &= value - 1; count += 1; }
    return count;
}

fn void put32(uchar* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) {
        output[offset + byte] = (uchar)(bits & 255);
        bits >>= 8;
    }
}

fn long bitset_xor_shift_trace(long* input, usz length, uchar* output, usz capacity)
    @export("bitset_xor_shift_trace") {
    if (input == null || length < 3 || length > 131) return -1;
    long n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > 4096 || q64 < 0 || q64 > 64) return -1;
    usz n = (usz)n64, q = (usz)q64;
    usz word_count = (n + 63) / 64, shift_offset = 2 + word_count;
    if (length != shift_offset + q) return -1;

    ulong[MAX_WORDS] words = zeroed;
    for (usz word = 0; word < word_count; word++) words[word] = (ulong)input[2 + word];
    usz tail_bits = n % 64;
    ulong tail_mask = tail_bits == 0 ? (ulong)-1 : ((ulong)1 << tail_bits) - 1;
    if ((words[word_count - 1] & ~tail_mask) != 0) return -1;
    for (usz operation = 0; operation < q; operation++) {
        long shift = input[shift_offset + operation];
        if (shift < -(n64 - 1) || shift > n64 - 1) return -1;
    }

    usz output_bytes = q * 4;
    if (output_bytes != 0 && (output == null || capacity < output_bytes)) return -2;
    int[MAX_OPERATIONS] counts = zeroed;
    for (usz operation = 0; operation < q; operation++) {
        long shift = input[shift_offset + operation];
        if (shift == 0) {
            for (usz word = 0; word < word_count; word++) words[word] = 0;
        } else if (shift > 0) {
            usz distance = (usz)shift, whole = distance / 64, part = distance % 64;
            for (usz destination = 0; destination < word_count; destination++) {
                usz source = destination + whole;
                ulong shifted = source < word_count ? words[source] >> part : 0;
                if (part != 0 && source + 1 < word_count) shifted |= words[source + 1] << (64 - part);
                words[destination] ^= shifted;
            }
        } else {
            usz distance = (usz)(-shift), whole = distance / 64, part = distance % 64;
            for (usz destination = word_count; destination > 0; destination--) {
                usz target = destination - 1;
                isz source = (isz)target - (isz)whole;
                ulong shifted = source >= 0 ? words[(usz)source] << part : 0;
                if (part != 0 && source > 0) shifted |= words[(usz)(source - 1)] >> (64 - part);
                words[target] ^= shifted;
            }
        }
        words[word_count - 1] &= tail_mask;
        uint count = 0;
        for (usz word = 0; word < word_count; word++) count += popcount64(words[word]);
        counts[operation] = (int)count;
    }
    for (usz operation = 0; operation < q; operation++) put32(output, operation * 4, counts[operation]);
    return (long)output_bytes;
}
