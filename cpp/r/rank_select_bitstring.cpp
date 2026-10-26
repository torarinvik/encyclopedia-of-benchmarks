#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxBits = 63;
constexpr std::size_t kMaxBlocks = 8;
constexpr std::size_t kMaxQueries = 16;
constexpr std::size_t kMaxInput = 35;
constexpr std::size_t kMaxOutputBytes = 128;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t rank_select_bitstring(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    const auto n_value = input[0], packed_value = input[1], query_value = input[2];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(kMaxBits) || packed_value < 0 ||
        query_value < 0 || query_value > static_cast<std::int64_t>(kMaxQueries)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto queries = static_cast<std::size_t>(query_value);
    const auto bits = static_cast<std::uint64_t>(packed_value);
    if ((bits >> n) != 0 || length != 3 + 2 * queries) return -1;
    const auto block_count = (n + 7) / 8;
    std::int64_t prefix[kMaxBlocks + 1]{};
    for (std::size_t block = 0; block < block_count; ++block) {
        prefix[block + 1] = prefix[block];
        const auto end = (8 * block + 8 < n) ? 8 * block + 8 : n;
        for (std::size_t pos = 8 * block; pos < end; ++pos) prefix[block + 1] += static_cast<std::int64_t>((bits >> pos) & 1U);
    }
    std::int64_t answers[kMaxQueries]{};
    for (std::size_t query = 0; query < queries; ++query) {
        const auto op = input[3 + 2 * query], index_value = input[4 + 2 * query];
        if ((op != 0 && op != 1) || index_value < 1 ||
            (op == 0 ? index_value > n_value : index_value > static_cast<std::int64_t>(kMaxBits + 1))) return -1;
        const auto index = static_cast<std::size_t>(index_value);
        if (op == 0) {
            const auto full_blocks = index / 8, remainder = index % 8;
            auto answer = prefix[full_blocks];
            for (std::size_t pos = 8 * full_blocks; pos < 8 * full_blocks + remainder; ++pos) answer += static_cast<std::int64_t>((bits >> pos) & 1U);
            answers[query] = answer;
        } else {
            auto block = std::size_t{0};
            while (block < block_count && prefix[block + 1] < static_cast<std::int64_t>(index)) ++block;
            answers[query] = -1;
            if (block < block_count) {
                auto remaining = index - static_cast<std::size_t>(prefix[block]);
                const auto end = (8 * block + 8 < n) ? 8 * block + 8 : n;
                for (std::size_t pos = 8 * block; pos < end; ++pos) {
                    if (((bits >> pos) & 1U) != 0 && --remaining == 0) { answers[query] = static_cast<std::int64_t>(pos) + 1; break; }
                }
            }
        }
    }
    const auto output_bytes = 8 * queries;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[kMaxOutputBytes]{};
    for (std::size_t query = 0; query < queries; ++query) store_i64_le(staged, 8 * query, answers[query]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
