module bm25_inverted_index;

// Build a bounded term-to-document table and rank one query by BM25.
fn long bm25_inverted_index(long* values, usz length, char* output, usz output_capacity)
    @export("bm25_inverted_index")
{
    if (values == null || length < 2 || length > 2114) return -2;
    if (values[0] < 0 || values[0] > 32) return -2;
    usz document_count = (usz)values[0];
    if (values[length - 1] < 1 || values[length - 1] > 255) return -2;
    long query = values[length - 1];
    long[32] frequency;
    long[32] document_length;
    long[32] document_id;
    bool[256] seen_ids;
    for (usz term = 0; term < 256; term++) {
        seen_ids[term] = false;
        if (term < 32) frequency[term] = 0;
    }
    usz offset = 1;
    long total_terms = 0;
    for (usz document = 0; document < document_count; document++) {
        if (offset + 2 > length - 1) return -2;
        long id = values[offset];
        long term_count = values[offset + 1];
        offset += 2;
        if (id < 0 || id > 255 || seen_ids[(usz)id]
            || term_count < 0 || term_count > 64
            || (usz)term_count > length - 1 - offset) return -2;
        seen_ids[(usz)id] = true;
        document_id[document] = id;
        document_length[document] = term_count;
        total_terms += term_count;
        for (usz item = 0; item < (usz)term_count; item++) {
            long term = values[offset];
            offset++;
            if (term < 1 || term > 255) return -2;
            if (term == query) frequency[document]++;
        }
    }
    if (offset != length - 1) return -2;

    long[32] result_id;
    long[32] result_tf;
    long[32] result_denominator;
    usz result_count = 0;
    for (usz document = 0; document < document_count; document++) {
        long tf = frequency[document];
        if (tf == 0) continue;
        long denominator = 8 * total_terms * tf + 3 * total_terms
                         + 9 * (long)document_count * document_length[document];
        usz position = result_count;
        while (position > 0) {
            usz previous = position - 1;
            long left = tf * result_denominator[previous];
            long right = result_tf[previous] * denominator;
            if (left < right || (left == right && document_id[document] > result_id[previous])) break;
            result_id[position] = result_id[previous];
            result_tf[position] = result_tf[previous];
            result_denominator[position] = result_denominator[previous];
            position--;
        }
        result_id[position] = document_id[document];
        result_tf[position] = tf;
        result_denominator[position] = denominator;
        result_count++;
    }
    if (output_capacity < result_count || (result_count != 0 && output == null)) return -2;
    for (usz index = 0; index < result_count; index++) output[index] = (char)result_id[index];
    return (long)result_count;
}
