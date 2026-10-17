module shannon_fano;

const usz MAX_TEXT_LENGTH = 64;
const usz MAX_PARSEABLE_INPUT_VALUES = 66;
const usz ASCII_SYMBOL_COUNT = 128;
const usz MAX_SYMBOLS = 10;
const usz MAX_CODE_LENGTH = 9;
const usz MAX_OUTPUT_BYTES = 111;

fn bool assign_codes(long* symbols, long* frequencies, usz start, usz end,
                     usz depth, char* prefix, char* code_bits, usz* code_lengths) {
    if (start == end) {
        usz symbol = (usz)symbols[start];
        for (usz index = 0; index < depth; index++) {
            code_bits[symbol * MAX_CODE_LENGTH + index] = prefix[index];
        }
        code_lengths[symbol] = depth;
        return true;
    }
    if (depth >= MAX_CODE_LENGTH) return false;

    usz total_frequency = 0;
    for (usz index = start; index <= end; index++) {
        total_frequency += (usz)frequencies[(usz)symbols[index]];
    }

    usz left_sum = 0;
    usz best_difference = MAX_TEXT_LENGTH + 1;
    usz split_index = start;
    for (usz index = start; index < end; index++) {
        left_sum += (usz)frequencies[(usz)symbols[index]];
        usz right_sum = total_frequency - left_sum;
        usz difference = left_sum > right_sum ? left_sum - right_sum : right_sum - left_sum;
        if (difference < best_difference) {
            best_difference = difference;
            split_index = index;
        }
    }

    prefix[depth] = '0';
    if (!assign_codes(symbols, frequencies, start, split_index, depth + 1,
                      prefix, code_bits, code_lengths)) return false;
    prefix[depth] = '1';
    return assign_codes(symbols, frequencies, split_index + 1, end, depth + 1,
                        prefix, code_bits, code_lengths);
}

fn long shannon_fano_generate_codes(long* input, usz input_length,
                                    char* output, usz output_capacity)
    @export("shannon_fano_generate_codes")
{
    if (input_length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input == null) {
        if (input_length != 0) return -1;
    } else {
        if (input_length == 0) return -1;
    }

    long[ASCII_SYMBOL_COUNT] frequencies = zeroed;
    if (input != null) {
        if (input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH) return -1;
        usz text_length = (usz)input[0];
        if (input_length != 1 + text_length) return -1;
        for (usz index = 0; index < text_length; index++) {
            long code = input[1 + index];
            if (code < 0 || code >= (long)ASCII_SYMBOL_COUNT) return -1;
            frequencies[(usz)code] += 1;
        }
    }

    long[MAX_SYMBOLS] symbols = zeroed;
    usz symbol_count = 0;
    bool[MAX_TEXT_LENGTH + 1] seen_frequency = zeroed;
    for (usz symbol = 0; symbol < ASCII_SYMBOL_COUNT; symbol++) {
        long frequency = frequencies[symbol];
        if (frequency == 0) continue;
        if (frequency < 0 || frequency > (long)MAX_TEXT_LENGTH ||
            seen_frequency[(usz)frequency] || symbol_count >= MAX_SYMBOLS) return -1;
        seen_frequency[(usz)frequency] = true;
        symbols[symbol_count] = (long)symbol;
        symbol_count++;
    }

    // Unique frequencies make the source's descending order unambiguous.
    for (usz index = 1; index < symbol_count; index++) {
        long symbol = symbols[index];
        usz position = index;
        while (position > 0 &&
               frequencies[(usz)symbols[position - 1]] < frequencies[(usz)symbol]) {
            symbols[position] = symbols[position - 1];
            position--;
        }
        symbols[position] = symbol;
    }

    char[ASCII_SYMBOL_COUNT * MAX_CODE_LENGTH] code_bits = zeroed;
    usz[ASCII_SYMBOL_COUNT] code_lengths = zeroed;
    if (symbol_count == 1) {
        usz symbol = (usz)symbols[0];
        code_bits[symbol * MAX_CODE_LENGTH] = '0';
        code_lengths[symbol] = 1;
    } else if (symbol_count > 1) {
        char[MAX_CODE_LENGTH] prefix = zeroed;
        if (!assign_codes(&symbols[0], &frequencies[0], 0, symbol_count - 1, 0,
                          &prefix[0], &code_bits[0], &code_lengths[0])) return -1;
    }

    char[MAX_OUTPUT_BYTES] staged = zeroed;
    usz staged_length = 0;
    staged[staged_length] = (char)symbol_count;
    staged_length++;
    for (usz symbol = 0; symbol < ASCII_SYMBOL_COUNT; symbol++) {
        usz code_length = code_lengths[symbol];
        if (code_length == 0) continue;
        staged[staged_length] = (char)symbol;
        staged_length++;
        staged[staged_length] = (char)code_length;
        staged_length++;
        for (usz index = 0; index < code_length; index++) {
            staged[staged_length] = code_bits[symbol * MAX_CODE_LENGTH + index];
            staged_length++;
        }
    }

    if (output == null || output_capacity < staged_length) return -2;
    for (usz index = 0; index < staged_length; index++) output[index] = staged[index];
    return (long)staged_length;
}
