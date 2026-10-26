module rank_select_bitstring;

const usz MAX_BITS = 63;
const usz MAX_BLOCKS = 8;
const usz MAX_QUERIES = 16;
const usz MAX_INPUT = 35;
const usz MAX_OUTPUT_BYTES = 128;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long rank_select_bitstring(long* input, usz length, char* output, usz capacity) @export("rank_select_bitstring") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0], packed_value = input[1], query_value = input[2];
    if (n_value < 1 || n_value > (long)MAX_BITS || packed_value < 0 || query_value < 0 || query_value > (long)MAX_QUERIES) return -1;
    usz n = (usz)n_value, queries = (usz)query_value;
    ulong bits = (ulong)packed_value;
    if ((bits >> n) != 0 || length != 3 + 2 * queries) return -1;
    usz block_count = (n + 7) / 8;
    long[MAX_BLOCKS + 1] prefix = zeroed;
    for (usz block = 0; block < block_count; block += 1) {
        prefix[block + 1] = prefix[block];
        usz end = 8 * block + 8 < n ? 8 * block + 8 : n;
        for (usz pos = 8 * block; pos < end; pos += 1) prefix[block + 1] += (long)((bits >> pos) & 1);
    }
    long[MAX_QUERIES] answers = zeroed;
    for (usz query = 0; query < queries; query += 1) {
        long op = input[3 + 2 * query], index_value = input[4 + 2 * query];
        if ((op != 0 && op != 1) || index_value < 1 ||
            (op == 0 ? index_value > n_value : index_value > (long)(MAX_BITS + 1))) return -1;
        usz index = (usz)index_value;
        if (op == 0) {
            usz full_blocks = index / 8, remainder = index % 8;
            long answer = prefix[full_blocks];
            for (usz pos = 8 * full_blocks; pos < 8 * full_blocks + remainder; pos += 1) answer += (long)((bits >> pos) & 1);
            answers[query] = answer;
        } else {
            usz block = 0;
            while (block < block_count && prefix[block + 1] < (long)index) block += 1;
            answers[query] = -1;
            if (block < block_count) {
                usz remaining = index - (usz)prefix[block];
                usz end = 8 * block + 8 < n ? 8 * block + 8 : n;
                for (usz pos = 8 * block; pos < end; pos += 1) {
                    if (((bits >> pos) & 1) != 0 && --remaining == 0) { answers[query] = (long)pos + 1; break; }
                }
            }
        }
    }
    usz output_bytes = 8 * queries;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    for (usz query = 0; query < queries; query += 1) store_i64_le(&staged[0], 8 * query, answers[query]);
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return (long)output_bytes;
}
