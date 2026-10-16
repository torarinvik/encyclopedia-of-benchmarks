module reverse_words_in_string;

const usz MAX_TEXT_LENGTH = 256;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_TEXT_LENGTH + 2;

fn bool is_trim_byte(long value) { return value >= 0 && value <= 32; }
fn bool is_split_space(long value) { return value == 32 || (value >= 9 && value <= 13); }

fn long reverse_words_in_string(long* input, usz length, char* output, usz capacity)
    @export("reverse_words_in_string")
{
    if (input == null || length == 0 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH || length != (usz)input[0] + 1) return -1;
    usz text_length = (usz)input[0];
    for (usz i = 0; i < text_length; i++)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;

    usz start = 0, end = text_length;
    while (start < end && is_trim_byte(input[start + 1])) start++;
    while (end > start && is_trim_byte(input[end])) end--;

    usz output_length = 0, word_count = 0, position = start;
    while (position < end) {
        while (position < end && is_split_space(input[position + 1])) position++;
        if (position == end) break;
        usz token_start = position;
        while (position < end && !is_split_space(input[position + 1])) position++;
        output_length += position - token_start;
        if (word_count > 0) output_length++;
        word_count++;
    }
    if (capacity < output_length || (output_length > 0 && output == null)) return -2;

    usz written = 0, emitted = 0;
    position = end;
    while (position > start) {
        while (position > start && is_split_space(input[position])) position--;
        if (position == start) break;
        usz token_end = position;
        while (position > start && !is_split_space(input[position])) position--;
        usz token_start = position;
        if (emitted > 0) output[written++] = ' ';
        for (usz i = token_start; i < token_end; i++) output[written++] = (char)input[i + 1];
        emitted++;
    }
    return (long)written;
}
