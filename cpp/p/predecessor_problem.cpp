#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 4096;
constexpr std::size_t max_words = (max_n + 63) / 64;
constexpr std::size_t max_queries = 512;
constexpr std::size_t max_input_length = 2 + max_words + 2 * max_queries;
constexpr std::size_t max_output_bytes = max_queries * 8;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

std::int64_t find_next(const std::uint64_t* words, std::size_t word_count,
                       std::size_t n, std::size_t key) {
    const std::size_t first_word = key / 64;
    for (std::size_t word = first_word; word < word_count; ++word) {
        const std::size_t first_bit = word == first_word ? key % 64 : 0;
        auto candidates = words[word];
        if (first_bit != 0) candidates &= UINT64_MAX << first_bit;
        if (candidates == 0) continue;
        const std::size_t end_bit = (word + 1) * 64 < n ? 64 : n - word * 64;
        for (std::size_t bit = first_bit; bit < end_bit; ++bit)
            if (((candidates >> bit) & 1U) != 0) return static_cast<std::int64_t>(word * 64 + bit);
    }
    return -1;
}

std::int64_t find_previous(const std::uint64_t* words, std::size_t n, std::size_t key) {
    const std::size_t first_word = key / 64;
    for (std::size_t word = first_word + 1; word > 0; --word) {
        const std::size_t index = word - 1;
        auto candidates = words[index];
        const std::size_t valid_bits = (index + 1) * 64 > n ? n - index * 64 : 64;
        const std::size_t requested_end = index == first_word ? key % 64 + 1 : valid_bits;
        const std::size_t end_bit = std::min(requested_end, valid_bits);
        const std::uint64_t mask = end_bit == 64 ? UINT64_MAX : (UINT64_C(1) << end_bit) - 1;
        candidates &= mask;
        if (candidates == 0) continue;
        for (std::size_t bit = end_bit; bit > 0; --bit)
            if (((candidates >> (bit - 1)) & 1U) != 0)
                return static_cast<std::int64_t>(index * 64 + bit - 1);
    }
    return -1;
}
}

extern "C" std::int64_t predecessor_problem(const std::int64_t* input, std::size_t length,
                                             std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto n_value = input[0], query_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)
        || query_value < 0 || query_value > static_cast<std::int64_t>(max_queries)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto queries = static_cast<std::size_t>(query_value);
    const auto word_count = (n + 63) / 64;
    const auto operation_offset = 2 + word_count;
    if (length != operation_offset + 2 * queries) return -1;
    std::uint64_t words[max_words]{};
    for (std::size_t word = 0; word < word_count; ++word) words[word] = static_cast<std::uint64_t>(input[2 + word]);
    const auto tail_bits = n % 64;
    if (tail_bits != 0 && (words[word_count - 1] >> tail_bits) != 0) return -1;
    for (std::size_t query = 0; query < queries; ++query) {
        const auto operation = input[operation_offset + 2 * query];
        const auto key = input[operation_offset + 2 * query + 1];
        if (operation < 0 || operation > 4 || key < 0 || key >= n_value) return -1;
    }
    std::int64_t answers[max_queries]{};
    std::size_t answer_count = 0;
    for (std::size_t query = 0; query < queries; ++query) {
        const auto operation = input[operation_offset + 2 * query];
        const auto key = static_cast<std::size_t>(input[operation_offset + 2 * query + 1]);
        const auto word = key / 64;
        const auto mask = UINT64_C(1) << (key % 64);
        if (operation == 0) words[word] |= mask;
        else if (operation == 1) words[word] &= ~mask;
        else if (operation == 2) answers[answer_count++] = (words[word] & mask) != 0;
        else if (operation == 3) answers[answer_count++] = find_next(words, word_count, n, key);
        else answers[answer_count++] = find_previous(words, n, key);
    }
    const auto output_bytes = answer_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[max_output_bytes]{};
    for (std::size_t index = 0; index < answer_count; ++index) store_i64_le(staged, index * 8, answers[index]);
    std::copy_n(staged, output_bytes, output);
    return static_cast<std::int64_t>(output_bytes);
}
