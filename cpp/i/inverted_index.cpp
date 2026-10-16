#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_DOCS = 256;
constexpr std::size_t MAX_WORDS_PER_DOC = 256;
constexpr std::size_t MAX_TOTAL_WORDS = 4096;
constexpr std::size_t MAX_QUERY_TERMS = 16;
constexpr std::size_t MAX_INPUT = 4627;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
std::uint64_t hash_i64(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8) hash = (hash ^ static_cast<std::uint8_t>(bits >> shift)) * FNV_PRIME;
    return hash;
}
}

extern "C" std::int64_t inverted_index(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > MAX_INPUT) return -1;
    const auto doc_count64 = input[0];
    if (doc_count64 < 0 || doc_count64 > static_cast<std::int64_t>(MAX_DOCS)) return -1;
    const auto doc_count = static_cast<std::size_t>(doc_count64);
    std::uint8_t seen_docs[MAX_DOCS]{};
    std::int32_t posting_heads[65536];
    std::int32_t posting_next[MAX_TOTAL_WORDS];
    std::uint8_t posting_doc[MAX_TOTAL_WORDS];
    for (std::size_t word = 0; word < 65536; ++word) posting_heads[word] = -1;
    std::size_t posting_count = 0;
    std::size_t total_words = 0, cursor = 1;

    for (std::size_t d = 0; d < doc_count; ++d) {
        if (cursor > length || length - cursor < 2) return -1;
        const auto doc_id64 = input[cursor++];
        const auto word_count64 = input[cursor++];
        if (doc_id64 < 0 || doc_id64 >= static_cast<std::int64_t>(MAX_DOCS) || word_count64 < 1 || word_count64 > static_cast<std::int64_t>(MAX_WORDS_PER_DOC)) return -1;
        const auto doc_id = static_cast<std::size_t>(doc_id64), word_count = static_cast<std::size_t>(word_count64);
        if (seen_docs[doc_id] || word_count > length - cursor || total_words > MAX_TOTAL_WORDS - word_count) return -1;
        seen_docs[doc_id] = 1;
        total_words += word_count;
        for (std::size_t w = 0; w < word_count; ++w) {
            const auto word_id64 = input[cursor++];
            if (word_id64 < 0 || word_id64 > 65535) return -1;
            const auto word_id = static_cast<std::size_t>(word_id64);
            bool duplicate = false;
            for (std::int32_t edge = posting_heads[word_id]; edge >= 0; edge = posting_next[edge]) {
                if (posting_doc[edge] == static_cast<std::uint8_t>(doc_id)) { duplicate = true; break; }
            }
            if (!duplicate) {
                if (posting_count >= MAX_TOTAL_WORDS) return -1;
                posting_doc[posting_count] = static_cast<std::uint8_t>(doc_id);
                posting_next[posting_count] = posting_heads[word_id];
                posting_heads[word_id] = static_cast<std::int32_t>(posting_count++);
            }
        }
    }
    if (cursor > length || length - cursor < 2) return -1;
    const auto operation = input[cursor++];
    const auto term_count64 = input[cursor++];
    if ((operation != 0 && operation != 1) || term_count64 < 1 || term_count64 > static_cast<std::int64_t>(MAX_QUERY_TERMS) || static_cast<std::size_t>(term_count64) != length - cursor) return -1;
    const auto term_count = static_cast<std::size_t>(term_count64);
    std::uint16_t terms[MAX_QUERY_TERMS];
    for (std::size_t i = 0; i < term_count; ++i) {
        if (input[cursor + i] < 0 || input[cursor + i] > 65535) return -1;
        terms[i] = static_cast<std::uint16_t>(input[cursor + i]);
    }

    std::uint8_t result_flags[MAX_DOCS]{};
    std::uint8_t term_flags[MAX_DOCS];
    for (std::size_t doc_id = 0; doc_id < MAX_DOCS; ++doc_id) result_flags[doc_id] = operation == 0 && seen_docs[doc_id];
    for (std::size_t t = 0; t < term_count; ++t) {
        for (std::size_t doc_id = 0; doc_id < MAX_DOCS; ++doc_id) term_flags[doc_id] = 0;
        for (std::int32_t edge = posting_heads[terms[t]]; edge >= 0; edge = posting_next[edge]) term_flags[posting_doc[edge]] = 1;
        for (std::size_t doc_id = 0; doc_id < MAX_DOCS; ++doc_id) {
            if (operation == 0) result_flags[doc_id] = static_cast<std::uint8_t>(result_flags[doc_id] && term_flags[doc_id]);
            else result_flags[doc_id] = static_cast<std::uint8_t>(result_flags[doc_id] || term_flags[doc_id]);
        }
    }
    std::int64_t result_ids[MAX_DOCS];
    std::size_t result_count = 0;
    for (std::size_t doc_id = 0; doc_id < MAX_DOCS; ++doc_id) {
        if (result_flags[doc_id]) result_ids[result_count++] = static_cast<std::int64_t>(doc_id);
    }
    auto hash = hash_i64(FNV_OFFSET, static_cast<std::int64_t>(result_count));
    for (std::size_t i = 0; i < result_count; ++i) hash = hash_i64(hash, result_ids[i]);
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
