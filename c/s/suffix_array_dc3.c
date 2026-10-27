#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT_LENGTH = 16, MAX_INPUT_LENGTH = 18, MAX_OUTPUT_BYTES = 128 };

static int64_t symbol_at(const int64_t *symbols, size_t length, size_t position)
{
    return position < length ? symbols[position] : 0;
}

static int64_t sample_rank(const int64_t *ranks, size_t length, size_t position)
{
    return position < length ? ranks[position] : -1;
}

static int triple_compare(const int64_t *symbols, size_t length,
                          size_t left, size_t right)
{
    for (size_t offset = 0; offset < 3; ++offset) {
        const int64_t a = symbol_at(symbols, length, left + offset);
        const int64_t b = symbol_at(symbols, length, right + offset);
        if (a != b) return a < b ? -1 : 1;
    }
    return 0;
}

static int suffix_compare(const int64_t *symbols, size_t length,
                          size_t left, size_t right)
{
    while (left < length && right < length) {
        if (symbols[left] != symbols[right]) return symbols[left] < symbols[right] ? -1 : 1;
        ++left;
        ++right;
    }
    if (left == length && right == length) return 0;
    return left == length ? -1 : 1;
}

static int zero_pair_compare(const int64_t *symbols, size_t length,
                             const int64_t *ranks, size_t left, size_t right)
{
    const int64_t left_symbol = symbol_at(symbols, length, left);
    const int64_t right_symbol = symbol_at(symbols, length, right);
    if (left_symbol != right_symbol) return left_symbol < right_symbol ? -1 : 1;
    const int64_t left_rank = sample_rank(ranks, length, left + 1);
    const int64_t right_rank = sample_rank(ranks, length, right + 1);
    if (left_rank != right_rank) return left_rank < right_rank ? -1 : 1;
    return 0;
}

static int merge_compare(const int64_t *symbols, size_t length,
                         const int64_t *ranks, size_t zero, size_t sample)
{
    const int64_t first_zero = symbol_at(symbols, length, zero);
    const int64_t first_sample = symbol_at(symbols, length, sample);
    if (first_zero != first_sample) return first_zero < first_sample ? -1 : 1;
    if (sample % 3 == 1) {
        const int64_t zero_rank = sample_rank(ranks, length, zero + 1);
        const int64_t sample_suffix_rank = sample_rank(ranks, length, sample + 1);
        if (zero_rank != sample_suffix_rank)
            return zero_rank < sample_suffix_rank ? -1 : 1;
    } else {
        const int64_t second_zero = symbol_at(symbols, length, zero + 1);
        const int64_t second_sample = symbol_at(symbols, length, sample + 1);
        if (second_zero != second_sample)
            return second_zero < second_sample ? -1 : 1;
        const int64_t zero_rank = sample_rank(ranks, length, zero + 2);
        const int64_t sample_suffix_rank = sample_rank(ranks, length, sample + 2);
        if (zero_rank != sample_suffix_rank)
            return zero_rank < sample_suffix_rank ? -1 : 1;
    }
    return 0;
}

static void dc3(const int64_t *symbols, size_t length, size_t *suffixes)
{
    if (length == 0) return;
    if (length <= 3) {
        for (size_t index = 0; index < length; ++index) suffixes[index] = index;
        for (size_t index = 1; index < length; ++index) {
            const size_t key = suffixes[index];
            size_t position = index;
            while (position > 0 && suffix_compare(symbols, length, key,
                                                  suffixes[position - 1]) < 0) {
                suffixes[position] = suffixes[position - 1];
                --position;
            }
            suffixes[position] = key;
        }
        return;
    }

    size_t sample_positions[MAX_TEXT_LENGTH];
    size_t sample_count = 0;
    for (size_t position = 1; position < length; ++position)
        if (position % 3 != 0) sample_positions[sample_count++] = position;

    for (size_t index = 1; index < sample_count; ++index) {
        const size_t key = sample_positions[index];
        size_t position = index;
        while (position > 0 && triple_compare(symbols, length, key,
                                               sample_positions[position - 1]) < 0) {
            sample_positions[position] = sample_positions[position - 1];
            --position;
        }
        sample_positions[position] = key;
    }

    int64_t triple_ranks[MAX_TEXT_LENGTH] = {0};
    int64_t next_rank = 0;
    for (size_t index = 0; index < sample_count; ++index) {
        if (index == 0 || triple_compare(symbols, length,
                                         sample_positions[index - 1],
                                         sample_positions[index]) != 0)
            ++next_rank;
        triple_ranks[sample_positions[index]] = next_rank;
    }

    size_t group_one_count = 0;
    for (size_t position = 1; position < length; position += 3) ++group_one_count;
    int64_t reduced[MAX_TEXT_LENGTH] = {0};
    size_t reduced_length = 0;
    for (size_t position = 1; position < length; position += 3)
        reduced[reduced_length++] = triple_ranks[position];
    reduced[reduced_length++] = 0;
    for (size_t position = 2; position < length; position += 3)
        reduced[reduced_length++] = triple_ranks[position];

    size_t reduced_order[MAX_TEXT_LENGTH];
    dc3(reduced, reduced_length, reduced_order);
    size_t sample_order[MAX_TEXT_LENGTH];
    int64_t ranks[MAX_TEXT_LENGTH];
    for (size_t index = 0; index < length; ++index) ranks[index] = -1;
    size_t sample_order_count = 0;
    for (size_t index = 0; index < reduced_length; ++index) {
        const size_t reduced_position = reduced_order[index];
        if (reduced_position == group_one_count) continue;
        const size_t source_position = reduced_position < group_one_count
            ? 1 + 3 * reduced_position
            : 2 + 3 * (reduced_position - group_one_count - 1);
        sample_order[sample_order_count] = source_position;
        ranks[source_position] = (int64_t)sample_order_count;
        ++sample_order_count;
    }

    size_t zero_positions[MAX_TEXT_LENGTH];
    size_t zero_count = 0;
    for (size_t position = 0; position < length; position += 3)
        zero_positions[zero_count++] = position;
    for (size_t index = 1; index < zero_count; ++index) {
        const size_t key = zero_positions[index];
        size_t position = index;
        while (position > 0 && zero_pair_compare(symbols, length, ranks, key,
                                                  zero_positions[position - 1]) < 0) {
            zero_positions[position] = zero_positions[position - 1];
            --position;
        }
        zero_positions[position] = key;
    }

    size_t zero_index = 0, sample_index = 0, output_index = 0;
    while (zero_index < zero_count && sample_index < sample_order_count) {
        const size_t zero = zero_positions[zero_index];
        const size_t sample = sample_order[sample_index];
        if (merge_compare(symbols, length, ranks, zero, sample) < 0)
            suffixes[output_index++] = zero_positions[zero_index++];
        else
            suffixes[output_index++] = sample_order[sample_index++];
    }
    while (zero_index < zero_count) suffixes[output_index++] = zero_positions[zero_index++];
    while (sample_index < sample_order_count) suffixes[output_index++] = sample_order[sample_index++];
}

int64_t suffix_array_dc3(const int64_t *values, size_t length,
                         uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_TEXT_LENGTH) return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 1) return -1;
    for (size_t index = 0; index < count; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 255) return -1;

    const size_t output_bytes = count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    if (count == 0) return 0;

    int64_t symbols[MAX_TEXT_LENGTH];
    for (size_t index = 0; index < count; ++index) symbols[index] = values[index + 1] + 1;
    size_t suffixes[MAX_TEXT_LENGTH];
    dc3(symbols, count, suffixes);
    for (size_t index = 0; index < count; ++index) {
        const uint64_t bits = (uint64_t)suffixes[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)output_bytes;
}
