module inverted_index;

const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_i64(ulong hash, long value) {
    ulong bits = (ulong)value;
    for (uint shift = 0; shift < 64; shift += 8) hash = (hash ^ (ulong)(uint8)(bits >> shift)) * FNV_PRIME;
    return hash;
}

fn long inverted_index(long* input, usz length) @export("inverted_index") {
    if (input == null || length < 3 || length > 4627) return -1;
    long doc_count64 = input[0];
    if (doc_count64 < 0 || doc_count64 > 256) return -1;
    usz doc_count = (usz)doc_count64;
    bool[256] seen_docs;
    int32[65536] posting_heads;
    int32[4096] posting_next;
    uint8[4096] posting_doc;
    usz posting_count = 0;
    usz total_words = 0, cursor = 1;
    for (usz i = 0; i < 256; i++) seen_docs[i] = false;
    for (usz i = 0; i < 65536; i++) posting_heads[i] = -1;

    for (usz d = 0; d < doc_count; d++) {
        if (cursor > length || length - cursor < 2) return -1;
        long doc_id64 = input[cursor++];
        long word_count64 = input[cursor++];
        if (doc_id64 < 0 || doc_id64 >= 256 || word_count64 < 1 || word_count64 > 256) return -1;
        usz doc_id = (usz)doc_id64, word_count = (usz)word_count64;
        if (seen_docs[doc_id] || word_count > length - cursor || total_words > 4096 - word_count) return -1;
        seen_docs[doc_id] = true;
        total_words += word_count;
        for (usz w = 0; w < word_count; w++) {
            long word_id64 = input[cursor++];
            if (word_id64 < 0 || word_id64 > 65535) return -1;
            usz word_id = (usz)word_id64;
            bool duplicate = false;
            for (int32 edge = posting_heads[word_id]; edge >= 0; edge = posting_next[edge]) {
                if ((usz)posting_doc[edge] == doc_id) { duplicate = true; break; }
            }
            if (!duplicate) {
                if (posting_count >= 4096) return -1;
                posting_doc[posting_count] = (uint8)doc_id;
                posting_next[posting_count] = posting_heads[word_id];
                posting_heads[word_id] = (int32)posting_count;
                posting_count++;
            }
        }
    }
    if (cursor > length || length - cursor < 2) return -1;
    long operation = input[cursor++];
    long term_count64 = input[cursor++];
    if ((operation != 0 && operation != 1) || term_count64 < 1 || term_count64 > 16 || (usz)term_count64 != length - cursor) return -1;
    usz term_count = (usz)term_count64;
    usz[16] terms;
    for (usz i = 0; i < term_count; i++) {
        if (input[cursor + i] < 0 || input[cursor + i] > 65535) return -1;
        terms[i] = (usz)input[cursor + i];
    }

    bool[256] result_flags;
    bool[256] term_flags;
    for (usz doc_id = 0; doc_id < 256; doc_id++) result_flags[doc_id] = operation == 0 && seen_docs[doc_id];
    for (usz t = 0; t < term_count; t++) {
        for (usz doc_id = 0; doc_id < 256; doc_id++) term_flags[doc_id] = false;
        for (int32 edge = posting_heads[terms[t]]; edge >= 0; edge = posting_next[edge]) term_flags[posting_doc[edge]] = true;
        for (usz doc_id = 0; doc_id < 256; doc_id++) {
            if (operation == 0) result_flags[doc_id] = result_flags[doc_id] && term_flags[doc_id];
            else result_flags[doc_id] = result_flags[doc_id] || term_flags[doc_id];
        }
    }
    long[256] result_ids;
    usz result_count = 0;
    for (usz doc_id = 0; doc_id < 256; doc_id++) {
        if (result_flags[doc_id]) result_ids[result_count++] = (long)doc_id;
    }
    ulong hash = hash_i64(FNV_OFFSET, (long)result_count);
    for (usz i = 0; i < result_count; i++) hash = hash_i64(hash, result_ids[i]);
    return (long)(hash & 0x7fffffffffffffff);
}
