/* Build a bounded term-to-document table and rank one query by BM25. */
#include <stddef.h>
#include <stdint.h>

int64_t bm25_inverted_index(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 2114) return -2;
    if (values[0] < 0 || values[0] > 32) return -2;
    const size_t document_count = (size_t)values[0];
    if (values[length - 1] < 1 || values[length - 1] > 255) return -2;
    const int64_t query = values[length - 1];
    int64_t frequency[32] = {0};
    int64_t document_length[32] = {0};
    int64_t document_id[32] = {0};
    uint8_t seen_ids[256] = {0};
    size_t offset = 1;
    int64_t total_terms = 0;

    for (size_t document = 0; document < document_count; ++document) {
        if (offset + 2 > length - 1) return -2;
        const int64_t id = values[offset];
        const int64_t term_count = values[offset + 1];
        offset += 2;
        if (id < 0 || id > 255 || seen_ids[id] != 0
            || term_count < 0 || term_count > 64
            || (size_t)term_count > length - 1 - offset) return -2;
        seen_ids[id] = 1;
        document_id[document] = id;
        document_length[document] = term_count;
        total_terms += term_count;
        for (size_t item = 0; item < (size_t)term_count; ++item) {
            const int64_t term = values[offset++];
            if (term < 1 || term > 255) return -2;
            if (term == query) ++frequency[document];
        }
    }
    if (offset != length - 1) return -2;

    int64_t result_id[32] = {0};
    int64_t result_tf[32] = {0};
    int64_t result_denominator[32] = {0};
    size_t result_count = 0;
    for (size_t document = 0; document < document_count; ++document) {
        const int64_t tf = frequency[document];
        if (tf == 0) continue;
        const int64_t denominator = 8 * total_terms * tf + 3 * total_terms
                                  + 9 * (int64_t)document_count * document_length[document];
        size_t position = result_count;
        while (position > 0) {
            const size_t previous = position - 1;
            const int64_t left = tf * result_denominator[previous];
            const int64_t right = result_tf[previous] * denominator;
            if (left < right || (left == right && document_id[document] > result_id[previous])) break;
            result_id[position] = result_id[previous];
            result_tf[position] = result_tf[previous];
            result_denominator[position] = result_denominator[previous];
            --position;
        }
        result_id[position] = document_id[document];
        result_tf[position] = tf;
        result_denominator[position] = denominator;
        ++result_count;
    }
    if (output_capacity < result_count || (result_count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < result_count; ++index) output[index] = (uint8_t)result_id[index];
    return (int64_t)result_count;
}
