/* Static range mode queries using whole-block modes and occurrence lists. */
#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 32, MaxQ = 16, MaxBlocks = 6, MaxInputLength = 66;

std::size_t lower_bound_i64(const std::array<std::int64_t, MaxN>& values,
                            std::size_t count, std::int64_t target) noexcept {
    std::size_t begin = 0, end = count;
    while (begin < end) {
        const auto middle = begin + (end - begin) / 2;
        if (values[middle] < target) begin = middle + 1;
        else end = middle;
    }
    return begin;
}

std::size_t lower_bound_size(const std::array<std::size_t, MaxN>& values,
                             std::size_t begin, std::size_t end,
                             std::size_t target) noexcept {
    while (begin < end) {
        const auto middle = begin + (end - begin) / 2;
        if (values[middle] < target) begin = middle + 1;
        else end = middle;
    }
    return begin;
}

std::size_t range_frequency(const std::array<std::size_t, MaxN>& occurrences,
                            const std::array<std::size_t, MaxN + 1>& offsets,
                            std::size_t id, std::size_t left, std::size_t right) noexcept {
    const auto begin = offsets[id], end = offsets[id + 1];
    return lower_bound_size(occurrences, begin, end, right) -
           lower_bound_size(occurrences, begin, end, left);
}

void write_i64(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
} // namespace

extern "C" std::int64_t static_range_mode_query(
    const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > MaxInputLength) return -1;
    const auto n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(MaxN) ||
        q_value < 1 || q_value > static_cast<std::int64_t>(MaxQ)) return -1;
    const auto n = static_cast<std::size_t>(n_value), q = static_cast<std::size_t>(q_value);
    if (length != 2 + n + 2 * q) return -1;
    for (std::size_t index = 0; index < n; ++index)
        if (input[2 + index] < 0 || input[2 + index] > 1'000'000'000) return -1;
    for (std::size_t query = 0; query < q; ++query) {
        const auto left = input[2 + n + 2 * query], right = input[3 + n + 2 * query];
        if (left < 0 || right <= left || right > n_value) return -1;
    }
    if (output == nullptr || output_capacity < 16 * q) return -2;

    std::array<std::int64_t, MaxN> sorted{}, unique_values{};
    std::array<std::size_t, MaxN> compressed{}, frequencies{}, cursor{}, occurrences{};
    std::array<std::size_t, MaxN + 1> offsets{};
    std::array<std::size_t, MaxBlocks * MaxBlocks> block_mode{};
    for (std::size_t index = 0; index < n; ++index) {
        const auto value = input[2 + index];
        auto position = index;
        while (position > 0 && sorted[position - 1] > value) {
            sorted[position] = sorted[position - 1];
            --position;
        }
        sorted[position] = value;
    }
    std::size_t distinct = 0;
    for (std::size_t index = 0; index < n; ++index)
        if (distinct == 0 || sorted[index] != unique_values[distinct - 1])
            unique_values[distinct++] = sorted[index];
    for (std::size_t index = 0; index < n; ++index) {
        const auto id = lower_bound_i64(unique_values, distinct, input[2 + index]);
        compressed[index] = id;
        ++frequencies[id];
    }
    for (std::size_t id = 0; id < distinct; ++id) offsets[id + 1] = offsets[id] + frequencies[id];
    for (std::size_t id = 0; id < distinct; ++id) cursor[id] = offsets[id];
    for (std::size_t index = 0; index < n; ++index)
        occurrences[cursor[compressed[index]]++] = index;

    std::size_t block_size = 1;
    while (block_size * block_size < n) ++block_size;
    const auto block_count = (n + block_size - 1) / block_size;
    std::array<std::size_t, MaxN> frequency{};
    for (std::size_t first = 0; first < block_count; ++first) {
        frequency.fill(0);
        std::size_t best_id = 0, best_count = 0;
        for (std::size_t last = first; last < block_count; ++last) {
            const auto begin = last * block_size;
            const auto end = std::min(n, begin + block_size);
            for (std::size_t index = begin; index < end; ++index) {
                const auto id = compressed[index], count = ++frequency[id];
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
            block_mode[first * MaxBlocks + last] = best_id;
        }
    }
    for (std::size_t query = 0; query < q; ++query) {
        const auto left = static_cast<std::size_t>(input[2 + n + 2 * query]);
        const auto right = static_cast<std::size_t>(input[3 + n + 2 * query]);
        const auto first_full = (left + block_size - 1) / block_size;
        const auto after_full = right / block_size;
        std::size_t best_id = 0, best_count = 0;
        if (first_full < after_full) {
            best_id = block_mode[first_full * MaxBlocks + after_full - 1];
            best_count = range_frequency(occurrences, offsets, best_id, left, right);
            const auto span_start = first_full * block_size, span_end = after_full * block_size;
            for (std::size_t index = left; index < span_start; ++index) {
                const auto id = compressed[index];
                const auto count = range_frequency(occurrences, offsets, id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
            for (std::size_t index = span_end; index < right; ++index) {
                const auto id = compressed[index];
                const auto count = range_frequency(occurrences, offsets, id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
        } else {
            for (std::size_t index = left; index < right; ++index) {
                const auto id = compressed[index];
                const auto count = range_frequency(occurrences, offsets, id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
        }
        write_i64(output, 16 * query, unique_values[best_id]);
        write_i64(output, 16 * query + 8, static_cast<std::int64_t>(best_count));
    }
    return static_cast<std::int64_t>(16 * q);
}
