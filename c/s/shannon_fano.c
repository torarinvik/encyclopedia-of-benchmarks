#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 64u
#define MAX_PARSEABLE_INPUT_VALUES 66u
#define ASCII_SYMBOL_COUNT 128u
#define MAX_SYMBOLS 10u
#define MAX_CODE_LENGTH 9u
#define MAX_OUTPUT_BYTES 111u

static int assign_codes(const uint8_t symbols[MAX_SYMBOLS],
                        const size_t frequencies[ASCII_SYMBOL_COUNT],
                        size_t start, size_t end, size_t depth,
                        uint8_t prefix[MAX_CODE_LENGTH],
                        uint8_t code_bits[ASCII_SYMBOL_COUNT][MAX_CODE_LENGTH],
                        uint8_t code_lengths[ASCII_SYMBOL_COUNT])
{
    if (start == end) {
        const uint8_t symbol = symbols[start];
        for (size_t index = 0u; index < depth; ++index) {
            code_bits[symbol][index] = prefix[index];
        }
        code_lengths[symbol] = (uint8_t)depth;
        return 1;
    }
    if (depth >= MAX_CODE_LENGTH) return 0;

    size_t total_frequency = 0u;
    for (size_t index = start; index <= end; ++index) {
        total_frequency += frequencies[symbols[index]];
    }

    size_t left_sum = 0u;
    size_t best_difference = SIZE_MAX;
    size_t split_index = start;
    for (size_t index = start; index < end; ++index) {
        left_sum += frequencies[symbols[index]];
        const size_t right_sum = total_frequency - left_sum;
        const size_t difference = left_sum > right_sum ? left_sum - right_sum : right_sum - left_sum;
        if (difference < best_difference) {
            best_difference = difference;
            split_index = index;
        }
    }

    prefix[depth] = (uint8_t)'0';
    if (!assign_codes(symbols, frequencies, start, split_index, depth + 1u,
                      prefix, code_bits, code_lengths)) return 0;
    prefix[depth] = (uint8_t)'1';
    return assign_codes(symbols, frequencies, split_index + 1u, end, depth + 1u,
                        prefix, code_bits, code_lengths);
}

int64_t shannon_fano_generate_codes(const int64_t *input, size_t input_length,
                                    uint8_t *output, size_t output_capacity)
{
    if (input_length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input == NULL) {
        if (input_length != 0u) return -1;
    } else {
        if (input_length == 0u) return -1;
    }

    size_t frequencies[ASCII_SYMBOL_COUNT] = {0u};
    if (input != NULL) {
        if (input[0] < 0 || input[0] > (int64_t)MAX_TEXT_LENGTH) return -1;
        const size_t text_length = (size_t)input[0];
        if (input_length != 1u + text_length) return -1;
        for (size_t index = 0u; index < text_length; ++index) {
            const int64_t code = input[1u + index];
            if (code < 0 || code >= (int64_t)ASCII_SYMBOL_COUNT) return -1;
            frequencies[(size_t)code] += 1u;
        }
    }

    uint8_t symbols[MAX_SYMBOLS] = {0u};
    size_t symbol_count = 0u;
    uint8_t seen_frequency[MAX_TEXT_LENGTH + 1u] = {0u};
    for (size_t symbol = 0u; symbol < ASCII_SYMBOL_COUNT; ++symbol) {
        const size_t frequency = frequencies[symbol];
        if (frequency == 0u) continue;
        if (frequency > MAX_TEXT_LENGTH || seen_frequency[frequency] != 0u ||
            symbol_count >= MAX_SYMBOLS) return -1;
        seen_frequency[frequency] = 1u;
        symbols[symbol_count++] = (uint8_t)symbol;
    }

    /* Unique frequencies make the source's descending order unambiguous. */
    for (size_t index = 1u; index < symbol_count; ++index) {
        const uint8_t symbol = symbols[index];
        size_t position = index;
        while (position > 0u && frequencies[symbols[position - 1u]] < frequencies[symbol]) {
            symbols[position] = symbols[position - 1u];
            --position;
        }
        symbols[position] = symbol;
    }

    uint8_t code_bits[ASCII_SYMBOL_COUNT][MAX_CODE_LENGTH] = {{0u}};
    uint8_t code_lengths[ASCII_SYMBOL_COUNT] = {0u};
    if (symbol_count == 1u) {
        code_bits[symbols[0]][0] = (uint8_t)'0';
        code_lengths[symbols[0]] = 1u;
    } else if (symbol_count > 1u) {
        uint8_t prefix[MAX_CODE_LENGTH] = {0u};
        if (!assign_codes(symbols, frequencies, 0u, symbol_count - 1u, 0u,
                          prefix, code_bits, code_lengths)) return -1;
    }

    uint8_t staged[MAX_OUTPUT_BYTES] = {0u};
    size_t staged_length = 0u;
    staged[staged_length++] = (uint8_t)symbol_count;
    for (size_t symbol = 0u; symbol < ASCII_SYMBOL_COUNT; ++symbol) {
        const uint8_t code_length = code_lengths[symbol];
        if (code_length == 0u) continue;
        staged[staged_length++] = (uint8_t)symbol;
        staged[staged_length++] = code_length;
        for (size_t index = 0u; index < (size_t)code_length; ++index) {
            staged[staged_length++] = code_bits[symbol][index];
        }
    }

    if (output == NULL || output_capacity < staged_length) return -2;
    for (size_t index = 0u; index < staged_length; ++index) output[index] = staged[index];
    return (int64_t)staged_length;
}
