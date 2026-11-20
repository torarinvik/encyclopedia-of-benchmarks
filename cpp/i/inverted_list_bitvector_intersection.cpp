#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_domain = 1024;
constexpr std::size_t max_lists = 16;
constexpr std::size_t max_words = 16;

void write_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t inverted_list_bitvector_intersection(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > 258) return -1;
    const auto domain_value = input[0];
    const auto list_count_value = input[1];
    if (domain_value < 1 || domain_value > static_cast<std::int64_t>(max_domain) ||
        list_count_value < 1 || list_count_value > static_cast<std::int64_t>(max_lists)) return -1;

    const auto domain = static_cast<std::size_t>(domain_value);
    const auto list_count = static_cast<std::size_t>(list_count_value);
    const std::size_t words_per_list = (domain + 63) / 64;
    if (length != 2 + list_count * words_per_list) return -1;

    const std::size_t remainder = domain % 64;
    if (remainder != 0) {
        const auto valid_mask = (std::uint64_t{1} << remainder) - 1;
        for (std::size_t list = 0; list < list_count; ++list) {
            const auto index = 2 + list * words_per_list + words_per_list - 1;
            const auto final_word = static_cast<std::uint64_t>(input[index]);
            if ((final_word & ~valid_mask) != 0) return -1;
        }
    }

    std::uint64_t intersection[max_words]{};
    for (std::size_t word = 0; word < words_per_list; ++word) {
        std::uint64_t combined = UINT64_MAX;
        for (std::size_t list = 0; list < list_count; ++list)
            combined &= static_cast<std::uint64_t>(input[2 + list * words_per_list + word]);
        intersection[word] = combined;
    }

    std::int64_t results[max_domain]{};
    std::size_t result_count = 0;
    for (std::size_t document_id = 0; document_id < domain; ++document_id) {
        const auto bit = std::uint64_t{1} << (document_id % 64);
        if ((intersection[document_id / 64] & bit) != 0)
            results[result_count++] = static_cast<std::int64_t>(document_id);
    }

    const std::size_t output_bytes = (result_count + 1) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    write_i64_le(output, 0, static_cast<std::int64_t>(result_count));
    for (std::size_t index = 0; index < result_count; ++index)
        write_i64_le(output, (index + 1) * 8, results[index]);
    return static_cast<std::int64_t>(output_bytes);
}
