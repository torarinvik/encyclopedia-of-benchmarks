#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_TEXT_LENGTH = 16;
constexpr std::size_t MAX_INPUT_LENGTH = 18;
constexpr std::size_t MAX_OUTPUT_BYTES = 128;

std::int64_t symbol_at(const std::int64_t *symbols, std::size_t length, std::size_t position) {
    return position < length ? symbols[position] : 0;
}

std::int64_t sample_rank(const std::int64_t *ranks, std::size_t length, std::size_t position) {
    return position < length ? ranks[position] : -1;
}

int triple_compare(const std::int64_t *symbols, std::size_t length,
                   std::size_t left, std::size_t right) {
    for (std::size_t offset = 0; offset < 3; ++offset) {
        const auto a = symbol_at(symbols, length, left + offset);
        const auto b = symbol_at(symbols, length, right + offset);
        if (a != b) return a < b ? -1 : 1;
    }
    return 0;
}

int suffix_compare(const std::int64_t *symbols, std::size_t length,
                   std::size_t left, std::size_t right) {
    while (left < length && right < length) {
        if (symbols[left] != symbols[right]) return symbols[left] < symbols[right] ? -1 : 1;
        ++left;
        ++right;
    }
    if (left == length && right == length) return 0;
    return left == length ? -1 : 1;
}

int zero_pair_compare(const std::int64_t *symbols, std::size_t length,
                      const std::int64_t *ranks, std::size_t left, std::size_t right) {
    const auto left_symbol = symbol_at(symbols, length, left);
    const auto right_symbol = symbol_at(symbols, length, right);
    if (left_symbol != right_symbol) return left_symbol < right_symbol ? -1 : 1;
    const auto left_rank = sample_rank(ranks, length, left + 1);
    const auto right_rank = sample_rank(ranks, length, right + 1);
    if (left_rank != right_rank) return left_rank < right_rank ? -1 : 1;
    return 0;
}

int merge_compare(const std::int64_t *symbols, std::size_t length,
                  const std::int64_t *ranks, std::size_t zero, std::size_t sample) {
    const auto first_zero = symbol_at(symbols, length, zero);
    const auto first_sample = symbol_at(symbols, length, sample);
    if (first_zero != first_sample) return first_zero < first_sample ? -1 : 1;
    if (sample % 3 == 1) {
        const auto zero_rank = sample_rank(ranks, length, zero + 1);
        const auto sample_suffix_rank = sample_rank(ranks, length, sample + 1);
        if (zero_rank != sample_suffix_rank) return zero_rank < sample_suffix_rank ? -1 : 1;
    } else {
        const auto second_zero = symbol_at(symbols, length, zero + 1);
        const auto second_sample = symbol_at(symbols, length, sample + 1);
        if (second_zero != second_sample) return second_zero < second_sample ? -1 : 1;
        const auto zero_rank = sample_rank(ranks, length, zero + 2);
        const auto sample_suffix_rank = sample_rank(ranks, length, sample + 2);
        if (zero_rank != sample_suffix_rank) return zero_rank < sample_suffix_rank ? -1 : 1;
    }
    return 0;
}

void dc3(const std::int64_t *symbols, std::size_t length, std::size_t *suffixes) {
    if (length == 0) return;
    if (length <= 3) {
        for (std::size_t i = 0; i < length; ++i) suffixes[i] = i;
        for (std::size_t i = 1; i < length; ++i) {
            const auto key = suffixes[i];
            auto position = i;
            while (position > 0 && suffix_compare(symbols, length, key, suffixes[position - 1]) < 0) {
                suffixes[position] = suffixes[position - 1];
                --position;
            }
            suffixes[position] = key;
        }
        return;
    }

    std::size_t sample_positions[MAX_TEXT_LENGTH];
    std::size_t sample_count = 0;
    for (std::size_t i = 1; i < length; ++i)
        if (i % 3 != 0) sample_positions[sample_count++] = i;
    for (std::size_t i = 1; i < sample_count; ++i) {
        const auto key = sample_positions[i];
        auto position = i;
        while (position > 0 && triple_compare(symbols, length, key, sample_positions[position - 1]) < 0) {
            sample_positions[position] = sample_positions[position - 1];
            --position;
        }
        sample_positions[position] = key;
    }

    std::int64_t triple_ranks[MAX_TEXT_LENGTH]{};
    std::int64_t next_rank = 0;
    for (std::size_t i = 0; i < sample_count; ++i) {
        if (i == 0 || triple_compare(symbols, length, sample_positions[i - 1], sample_positions[i]) != 0)
            ++next_rank;
        triple_ranks[sample_positions[i]] = next_rank;
    }

    std::size_t group_one_count = 0;
    for (std::size_t i = 1; i < length; i += 3) ++group_one_count;
    std::int64_t reduced[MAX_TEXT_LENGTH]{};
    std::size_t reduced_length = 0;
    for (std::size_t i = 1; i < length; i += 3) reduced[reduced_length++] = triple_ranks[i];
    reduced[reduced_length++] = 0;
    for (std::size_t i = 2; i < length; i += 3) reduced[reduced_length++] = triple_ranks[i];
    std::size_t reduced_order[MAX_TEXT_LENGTH];
    dc3(reduced, reduced_length, reduced_order);

    std::size_t sample_order[MAX_TEXT_LENGTH];
    std::int64_t ranks[MAX_TEXT_LENGTH];
    for (std::size_t i = 0; i < length; ++i) ranks[i] = -1;
    std::size_t sample_order_count = 0;
    for (std::size_t i = 0; i < reduced_length; ++i) {
        const auto reduced_position = reduced_order[i];
        if (reduced_position == group_one_count) continue;
        const auto source_position = reduced_position < group_one_count
            ? 1 + 3 * reduced_position
            : 2 + 3 * (reduced_position - group_one_count - 1);
        sample_order[sample_order_count] = source_position;
        ranks[source_position] = static_cast<std::int64_t>(sample_order_count++);
    }

    std::size_t zero_positions[MAX_TEXT_LENGTH];
    std::size_t zero_count = 0;
    for (std::size_t i = 0; i < length; i += 3) zero_positions[zero_count++] = i;
    for (std::size_t i = 1; i < zero_count; ++i) {
        const auto key = zero_positions[i];
        auto position = i;
        while (position > 0 && zero_pair_compare(symbols, length, ranks, key, zero_positions[position - 1]) < 0) {
            zero_positions[position] = zero_positions[position - 1];
            --position;
        }
        zero_positions[position] = key;
    }

    std::size_t zi = 0, si = 0, oi = 0;
    while (zi < zero_count && si < sample_order_count) {
        const auto zero = zero_positions[zi];
        const auto sample = sample_order[si];
        if (merge_compare(symbols, length, ranks, zero, sample) < 0) suffixes[oi++] = zero_positions[zi++];
        else suffixes[oi++] = sample_order[si++];
    }
    while (zi < zero_count) suffixes[oi++] = zero_positions[zi++];
    while (si < sample_order_count) suffixes[oi++] = sample_order[si++];
}
} // namespace

extern "C" std::int64_t suffix_array_dc3(const std::int64_t *values,
        std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (values == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const auto count_value = values[0];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(MAX_TEXT_LENGTH)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 1) return -1;
    for (std::size_t i = 0; i < count; ++i)
        if (values[i + 1] < 0 || values[i + 1] > 255) return -1;
    const auto output_bytes = count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    if (count == 0) return 0;
    std::int64_t symbols[MAX_TEXT_LENGTH];
    for (std::size_t i = 0; i < count; ++i) symbols[i] = values[i + 1] + 1;
    std::size_t suffixes[MAX_TEXT_LENGTH];
    dc3(symbols, count, suffixes);
    for (std::size_t i = 0; i < count; ++i) {
        const auto bits = static_cast<std::uint64_t>(suffixes[i]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(output_bytes);
}
