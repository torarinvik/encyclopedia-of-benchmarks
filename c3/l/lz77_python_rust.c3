module lz77_python_rust;

const usz MAX_TEXT_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 66;
const usz MAX_OUTPUT_BYTES = 1536;

fn void store_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long lz77_python_rust_compress(long* input, usz input_length, uint8* output, usz capacity)
    @export("lz77_python_rust_compress") {
    if (input == null || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1L;
    if (input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH) return -1L;
    usz text_length = (usz)input[0];
    if (input_length != 1 + text_length) return -1L;
    for (usz index = 0; index < text_length; index++)
        if (input[index + 1] < 32 || input[index + 1] > 126) return -1L;
    if (text_length > 0) {
        long final_character = input[text_length];
        usz occurrences = 0;
        for (usz index = 0; index < text_length; index++)
            if (input[index + 1] == final_character) occurrences++;
        if (occurrences != 1) return -1L;
    }

    uint8[MAX_OUTPUT_BYTES] staged = zeroed;
    usz token_count = 0;
    usz current = 0;
    while (current < text_length) {
        usz best_offset = 0, best_length = 0;
        usz search_start = current > 7 ? current - 7 : 0;
        for (usz candidate = search_start; candidate < current; candidate++) {
            usz offset = current - candidate;
            usz match_length = 0;
            while (current + match_length < text_length) {
                usz source = candidate + match_length;
                if (source >= current) source = candidate + match_length % offset;
                if (input[source + 1] != input[current + match_length + 1]) break;
                match_length++;
            }
            if (match_length >= text_length - current) return -1L;
            if (match_length >= best_length) {
                best_offset = offset;
                best_length = match_length;
            }
        }
        if (best_length >= text_length - current) return -1L;
        long indicator = input[current + best_length + 1];
        usz byte_offset = token_count * 24;
        store_i64_le(&staged[0], byte_offset, (long)best_offset);
        store_i64_le(&staged[0], byte_offset + 8, (long)best_length);
        store_i64_le(&staged[0], byte_offset + 16, indicator);
        token_count++;
        current += best_length + 1;
    }

    usz output_bytes = token_count * 24;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1L;
    if (output == null || capacity < output_bytes) return -2L;
    for (usz index = 0; index < output_bytes; index++) output[index] = staged[index];
    return (long)output_bytes;
}
