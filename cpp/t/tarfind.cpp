/* Bounded clean-room TAR-header filename search benchmark.
 * Embench-IoT source declares MIT; see the package attribution.
 */
/* SPDX-License-Identifier: MIT */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_records = 35;
constexpr std::size_t max_queries = 5;
constexpr std::size_t min_name_length = 5;
constexpr std::size_t max_name_length = 39;
constexpr std::size_t max_input_length =
    2 + max_records * (1 + max_name_length) + max_queries * (1 + max_name_length);
}

extern "C" std::int64_t tarfind(const std::int64_t *input,
                                         std::size_t length,
                                         std::uint8_t *output,
                                         std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_records) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_queries)) return -1;
    const auto record_count = static_cast<std::size_t>(input[0]);
    const auto query_count = static_cast<std::size_t>(input[1]);
    std::size_t record_offsets[max_records], record_lengths[max_records];
    std::size_t query_offsets[max_queries], query_lengths[max_queries];
    std::uint8_t staged[max_queries]{};
    std::size_t position = 2;

    for (std::size_t i = 0; i < record_count; ++i) {
        if (position >= length) return -1;
        const auto raw_length = input[position++];
        if (raw_length < static_cast<std::int64_t>(min_name_length) ||
            raw_length > static_cast<std::int64_t>(max_name_length)) return -1;
        const auto name_length = static_cast<std::size_t>(raw_length);
        if (name_length > length - position) return -1;
        record_offsets[i] = position;
        record_lengths[i] = name_length;
        for (std::size_t j = 0; j < name_length; ++j)
            if (input[position + j] < 'A' || input[position + j] > 'Z') return -1;
        position += name_length;
    }
    for (std::size_t i = 0; i < query_count; ++i) {
        if (position >= length) return -1;
        const auto raw_length = input[position++];
        if (raw_length < static_cast<std::int64_t>(min_name_length) ||
            raw_length > static_cast<std::int64_t>(max_name_length)) return -1;
        const auto name_length = static_cast<std::size_t>(raw_length);
        if (name_length > length - position) return -1;
        query_offsets[i] = position;
        query_lengths[i] = name_length;
        for (std::size_t j = 0; j < name_length; ++j)
            if (input[position + j] < 'A' || input[position + j] > 'Z') return -1;
        position += name_length;
    }
    if (position != length) return -1;
    if (output == nullptr || capacity < query_count) return -2;

    for (std::size_t q = 0; q < query_count; ++q) {
        std::int64_t found = -1;
        for (std::size_t i = 0; i < record_count; ++i) {
            if (record_lengths[i] != query_lengths[q]) continue;
            std::size_t j = 0;
            while (j < query_lengths[q] &&
                   input[record_offsets[i] + j] == input[query_offsets[q] + j]) ++j;
            if (j == query_lengths[q]) {
                found = static_cast<std::int64_t>(i);
                break;
            }
        }
        staged[q] = found < 0 ? UINT8_MAX : static_cast<std::uint8_t>(found);
    }
    for (std::size_t q = 0; q < query_count; ++q) output[q] = staged[q];
    return static_cast<std::int64_t>(query_count);
}
