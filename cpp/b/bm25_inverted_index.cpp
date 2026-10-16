/* Build a bounded term-to-document table and rank one query by BM25. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t bm25_inverted_index(const std::int64_t *values, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > 2114 || values[0] < 0 || values[0] > 32) return -2;
    const auto document_count = static_cast<std::size_t>(values[0]);
    if (values[length - 1] < 1 || values[length - 1] > 255) return -2;
    const auto query = values[length - 1];
    std::int64_t frequency[32]{};
    std::int64_t document_length[32]{};
    std::int64_t document_id[32]{};
    bool seen_ids[256]{};
    std::size_t offset = 1;
    std::int64_t total_terms = 0;
    for (std::size_t document = 0; document < document_count; ++document) {
        if (offset + 2 > length - 1) return -2;
        const auto id = values[offset];
        const auto term_count = values[offset + 1];
        offset += 2;
        if (id < 0 || id > 255 || seen_ids[id] || term_count < 0 || term_count > 64
            || static_cast<std::uint64_t>(term_count) > length - 1 - offset) return -2;
        seen_ids[id] = true;
        document_id[document] = id;
        document_length[document] = term_count;
        total_terms += term_count;
        for (std::size_t item = 0; item < static_cast<std::size_t>(term_count); ++item) {
            const auto term = values[offset++];
            if (term < 1 || term > 255) return -2;
            if (term == query) ++frequency[document];
        }
    }
    if (offset != length - 1) return -2;

    std::int64_t result_id[32]{};
    std::int64_t result_tf[32]{};
    std::int64_t result_denominator[32]{};
    std::size_t result_count = 0;
    for (std::size_t document = 0; document < document_count; ++document) {
        const auto tf = frequency[document];
        if (tf == 0) continue;
        const auto denominator = 8 * total_terms * tf + 3 * total_terms
                               + 9 * static_cast<std::int64_t>(document_count) * document_length[document];
        auto position = result_count;
        while (position > 0) {
            const auto previous = position - 1;
            const auto left = tf * result_denominator[previous];
            const auto right = result_tf[previous] * denominator;
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
    if (output_capacity < result_count || (result_count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < result_count; ++index)
        output[index] = static_cast<std::uint8_t>(result_id[index]);
    return static_cast<std::int64_t>(result_count);
}
