module bpe_tokenizer;

// Apply bounded byte-pair merges with first-seen tie-breaking.
fn long bpe_tokenizer(long* values, usz length, char* output, usz output_capacity)
    @export("bpe_tokenizer")
{
    if (values == null || length < 2 || length > 515) return -2;
    long merge_count_value = values[0];
    long byte_count_value = values[1];
    if (merge_count_value < 0 || merge_count_value > 32 || byte_count_value < 0
        || byte_count_value > 512 || length != (usz)byte_count_value + 2) return -2;
    usz byte_count = (usz)byte_count_value;
    long[512] tokens;
    long[512] next_tokens;
    for (usz index = 0; index < byte_count; index++) {
        if (values[index + 2] < 0 || values[index + 2] > 255) return -2;
        tokens[index] = values[index + 2];
    }
    usz token_count = byte_count;
    for (usz step = 0; step < (usz)merge_count_value && token_count > 1; step++) {
        long[511] pair_left;
        long[511] pair_right;
        long[511] pair_frequency;
        usz unique_pairs = 0;
        for (usz index = 0; index + 1 < token_count; index++) {
            usz pair_index = 0;
            while (pair_index < unique_pairs
                && (pair_left[pair_index] != tokens[index] || pair_right[pair_index] != tokens[index + 1])) pair_index++;
            if (pair_index == unique_pairs) {
                pair_left[pair_index] = tokens[index];
                pair_right[pair_index] = tokens[index + 1];
                pair_frequency[pair_index] = 1;
                unique_pairs++;
            } else {
                pair_frequency[pair_index]++;
            }
        }
        if (unique_pairs == 0) break;
        usz best = 0;
        for (usz index = 1; index < unique_pairs; index++) {
            if (pair_frequency[index] > pair_frequency[best]) best = index;
        }
        if (pair_frequency[best] == 1) break;
        usz next_count = 0;
        usz index = 0;
        while (index < token_count) {
            if (index + 1 < token_count && tokens[index] == pair_left[best]
                && tokens[index + 1] == pair_right[best]) {
                next_tokens[next_count] = 256 + (long)step;
                next_count++;
                index += 2;
            } else {
                next_tokens[next_count] = tokens[index];
                next_count++;
                index++;
            }
        }
        for (usz item = 0; item < next_count; item++) tokens[item] = next_tokens[item];
        token_count = next_count;
    }
    if (token_count > output_capacity / 2 || (token_count != 0 && output == null)) return -2;
    for (usz index = 0; index < token_count; index++) {
        long token = tokens[index];
        output[index * 2] = (char)(token & 255);
        output[index * 2 + 1] = (char)((token >> 8) & 255);
    }
    return (long)token_count;
}
