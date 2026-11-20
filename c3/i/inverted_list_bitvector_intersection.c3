module inverted_list_bitvector_intersection;

const usz MAX_DOMAIN = 1024;
const usz MAX_LISTS = 16;
const usz MAX_WORDS = 16;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long inverted_list_bitvector_intersection(long* input, usz length,
    char* output, usz output_capacity) @export("inverted_list_bitvector_intersection") {
    if (input == null || length < 2 || length > 258) return -1;
    long domain_value = input[0];
    long list_count_value = input[1];
    if (domain_value < 1 || domain_value > (long)MAX_DOMAIN ||
        list_count_value < 1 || list_count_value > (long)MAX_LISTS) return -1;

    usz domain = (usz)domain_value;
    usz list_count = (usz)list_count_value;
    usz words_per_list = (domain + 63) / 64;
    if (length != 2 + list_count * words_per_list) return -1;

    usz remainder = domain % 64;
    if (remainder != 0) {
        ulong valid_mask = (1UL << remainder) - 1;
        for (usz list = 0; list < list_count; list++) {
            usz index = 2 + list * words_per_list + words_per_list - 1;
            ulong final_word = (ulong)input[index];
            if ((final_word & ~valid_mask) != 0) return -1;
        }
    }

    ulong[MAX_WORDS] intersection = zeroed;
    for (usz word = 0; word < words_per_list; word++) {
        ulong combined = ~0UL;
        for (usz list = 0; list < list_count; list++)
            combined &= (ulong)input[2 + list * words_per_list + word];
        intersection[word] = combined;
    }

    long[MAX_DOMAIN] results = zeroed;
    usz result_count = 0;
    for (usz document_id = 0; document_id < domain; document_id++) {
        ulong bit = 1UL << (document_id % 64);
        if ((intersection[document_id / 64] & bit) != 0) {
            results[result_count++] = (long)document_id;
        }
    }

    usz output_bytes = (result_count + 1) * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    write_i64_le(output, 0, (long)result_count);
    for (usz index = 0; index < result_count; index++)
        write_i64_le(output, (index + 1) * 8, results[index]);
    return (long)output_bytes;
}
