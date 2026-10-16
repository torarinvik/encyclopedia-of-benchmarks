#include <stddef.h>
#include <stdint.h>

#define MAX_DOCS 256
#define MAX_WORDS_PER_DOC 256
#define MAX_TOTAL_WORDS 4096
#define MAX_QUERY_TERMS 16
#define MAX_INPUT 4627
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_i64(uint64_t hash, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8) hash = (hash ^ (uint8_t)(bits >> shift)) * FNV_PRIME;
    return hash;
}

int64_t inverted_index(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t doc_count64 = input[0];
    if (doc_count64 < 0 || doc_count64 > MAX_DOCS) return -1;
    const size_t doc_count = (size_t)doc_count64;
    uint8_t seen_docs[MAX_DOCS] = {0};
    int32_t posting_heads[65536];
    int32_t posting_next[MAX_TOTAL_WORDS];
    uint8_t posting_doc[MAX_TOTAL_WORDS];
    for (size_t word = 0; word < 65536; ++word) posting_heads[word] = -1;
    size_t posting_count = 0;
    size_t total_words = 0, cursor = 1;

    for (size_t d = 0; d < doc_count; ++d) {
        if (cursor > length || length - cursor < 2) return -1;
        const int64_t doc_id64 = input[cursor++];
        const int64_t word_count64 = input[cursor++];
        if (doc_id64 < 0 || doc_id64 >= MAX_DOCS || word_count64 < 1 || word_count64 > MAX_WORDS_PER_DOC) return -1;
        const size_t doc_id = (size_t)doc_id64, word_count = (size_t)word_count64;
        if (seen_docs[doc_id] || word_count > length - cursor || total_words > MAX_TOTAL_WORDS - word_count) return -1;
        seen_docs[doc_id] = 1;
        total_words += word_count;
        for (size_t w = 0; w < word_count; ++w) {
            const int64_t word_id64 = input[cursor++];
            if (word_id64 < 0 || word_id64 > 65535) return -1;
            const size_t word_id = (size_t)word_id64;
            int duplicate = 0;
            for (int32_t edge = posting_heads[word_id]; edge >= 0; edge = posting_next[edge]) {
                if (posting_doc[edge] == (uint8_t)doc_id) { duplicate = 1; break; }
            }
            if (!duplicate) {
                if (posting_count >= MAX_TOTAL_WORDS) return -1;
                posting_doc[posting_count] = (uint8_t)doc_id;
                posting_next[posting_count] = posting_heads[word_id];
                posting_heads[word_id] = (int32_t)posting_count++;
            }
        }
    }
    if (cursor > length || length - cursor < 2) return -1;
    const int64_t operation = input[cursor++];
    const int64_t term_count64 = input[cursor++];
    if ((operation != 0 && operation != 1) || term_count64 < 1 || term_count64 > MAX_QUERY_TERMS || (size_t)term_count64 != length - cursor) return -1;
    const size_t term_count = (size_t)term_count64;
    uint16_t terms[MAX_QUERY_TERMS];
    for (size_t i = 0; i < term_count; ++i) {
        if (input[cursor + i] < 0 || input[cursor + i] > 65535) return -1;
        terms[i] = (uint16_t)input[cursor + i];
    }

    uint8_t result_flags[MAX_DOCS];
    uint8_t term_flags[MAX_DOCS];
    for (size_t doc_id = 0; doc_id < MAX_DOCS; ++doc_id) result_flags[doc_id] = operation == 0 && seen_docs[doc_id];
    for (size_t t = 0; t < term_count; ++t) {
        for (size_t doc_id = 0; doc_id < MAX_DOCS; ++doc_id) term_flags[doc_id] = 0;
        for (int32_t edge = posting_heads[terms[t]]; edge >= 0; edge = posting_next[edge]) term_flags[posting_doc[edge]] = 1;
        for (size_t doc_id = 0; doc_id < MAX_DOCS; ++doc_id) {
            if (operation == 0) result_flags[doc_id] = (uint8_t)(result_flags[doc_id] && term_flags[doc_id]);
            else result_flags[doc_id] = (uint8_t)(result_flags[doc_id] || term_flags[doc_id]);
        }
    }
    int64_t result_ids[MAX_DOCS];
    size_t result_count = 0;
    for (size_t doc_id = 0; doc_id < MAX_DOCS; ++doc_id) {
        if (result_flags[doc_id]) result_ids[result_count++] = (int64_t)doc_id;
    }
    uint64_t hash = hash_i64(FNV_OFFSET, (int64_t)result_count);
    for (size_t i = 0; i < result_count; ++i) hash = hash_i64(hash, result_ids[i]);
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
