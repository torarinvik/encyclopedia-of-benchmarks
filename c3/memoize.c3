module memoize;

const usz MIN_ARITY = 0;
const usz MAX_ARITY = 4;
const usz MAX_CALLS = 64;
const long MIN_ARGUMENT = -100;
const long MAX_ARGUMENT = 100;
const usz MAX_VALID_INPUT_LENGTH = 258;
const usz MAX_PARSEABLE_INPUT_LENGTH = 259;
const usz MAX_OUTPUT_BYTES = 520;
const long ENCODING_BASE = 201;

fn void store_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long memoize(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("memoize") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[0] < (long)MIN_ARITY || input[0] > (long)MAX_ARITY ||
        input[1] < 0 || input[1] > (long)MAX_CALLS) return -1L;

    usz arity = (usz)input[0];
    usz call_count = (usz)input[1];
    if (input_length != 2 + arity * call_count) return -1L;
    for (usz index = 2; index < input_length; index++)
        if (input[index] < MIN_ARGUMENT || input[index] > MAX_ARGUMENT) return -1L;

    uint8[MAX_OUTPUT_BYTES] staged = zeroed;
    long[MAX_CALLS] cached_callback_results = zeroed;
    usz miss_count = 0;
    for (usz call = 0; call < call_count; call++) {
        long result = 0;
        for (usz argument = 0; argument < arity; argument++) {
            long value = input[2 + call * arity + argument];
            result = result * ENCODING_BASE + (value - MIN_ARGUMENT);
        }

        // For fixed arity this injective encoding distinguishes JSON-array keys.
        usz prior = 0;
        while (prior < miss_count && cached_callback_results[prior] != result) prior++;
        if (prior == miss_count) {
            cached_callback_results[miss_count] = result;
            miss_count++;
        }
        store_i64_le(staged, call * 8, result);
    }

    usz output_bytes = 8 * (call_count + 1);
    store_i64_le(staged, call_count * 8, (long)miss_count);
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz index = 0; index < output_bytes; index++) output[index] = staged[index];
    return (long)output_bytes;
}
