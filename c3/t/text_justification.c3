module text_justification;

const usz MAX_WIDTH = 64;
const usz MAX_TEXT_BYTES = 512;
const usz MAX_WORDS = 64;
const usz MAX_INPUT_LENGTH = 2 + MAX_TEXT_BYTES + 1;
const usz MAX_OUTPUT_BYTES = MAX_WORDS * MAX_WIDTH + MAX_WORDS;

fn long text_justification(long* input, usz length, char* output,
                           usz output_capacity)
    @export("text_justification")
{
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) { return -1; }
    long width_value = input[0];
    long text_length_value = input[1];
    if (width_value < 1 || width_value > (long)MAX_WIDTH ||
        text_length_value < 0 || text_length_value > (long)MAX_TEXT_BYTES ||
        length != 2 + (usz)text_length_value) { return -1; }
    usz width = (usz)width_value;
    usz text_length = (usz)text_length_value;

    u8[MAX_TEXT_BYTES] text;
    for (usz index = 0; index < text_length; index++) {
        long value = input[index + 2];
        if (value != 32 && (value < 33 || value > 126)) { return -1; }
        text[index] = (u8)value;
    }

    usz[MAX_WORDS] starts;
    usz[MAX_WORDS] lengths;
    usz word_count = 0;
    usz index = 0;
    while (index < text_length) {
        while (index < text_length && text[index] == ' ') { index++; }
        if (index == text_length) { break; }
        usz start = index;
        while (index < text_length && text[index] != ' ') { index++; }
        usz word_length = index - start;
        if (word_count == MAX_WORDS || word_length > width) { return -1; }
        starts[word_count] = start;
        lengths[word_count] = word_length;
        word_count++;
    }

    u8[MAX_OUTPUT_BYTES] result = zeroed;
    usz result_length = 0;
    usz line_start = 0;
    usz line_end = 0;
    usz letters = 0;
    bool first_line = true;
    for (usz word = 0; word < word_count; word++) {
        if (letters + lengths[word] + (line_end - line_start) <= width) {
            letters += lengths[word];
            line_end++;
            continue;
        }
        if (!first_line) { result[result_length++] = '\n'; }
        first_line = false;
        usz count = line_end - line_start;
        if (count == 1) {
            for (usz i = 0; i < lengths[line_start]; i++) {
                result[result_length++] = text[starts[line_start] + i];
            }
            for (usz i = lengths[line_start]; i < width; i++) {
                result[result_length++] = ' ';
            }
        } else {
            usz gaps = count - 1;
            usz spaces = width - letters;
            usz base = spaces / gaps;
            usz extra = spaces % gaps;
            for (usz item = 0; item < count; item++) {
                usz current = line_start + item;
                for (usz i = 0; i < lengths[current]; i++) {
                    result[result_length++] = text[starts[current] + i];
                }
                if (item + 1 < count) {
                    usz gap_spaces = base + (item < extra ? 1 : 0);
                    for (usz i = 0; i < gap_spaces; i++) {
                        result[result_length++] = ' ';
                    }
                }
            }
        }
        line_start = word;
        line_end = word + 1;
        letters = lengths[word];
    }

    if (!first_line) { result[result_length++] = '\n'; }
    for (usz item = line_start; item < line_end; item++) {
        if (item != line_start) { result[result_length++] = ' '; }
        for (usz i = 0; i < lengths[item]; i++) {
            result[result_length++] = text[starts[item] + i];
        }
    }
    usz trailing_spaces = width - letters - (line_end - line_start) + 1;
    for (usz i = 0; i < trailing_spaces; i++) { result[result_length++] = ' '; }

    if (output_capacity < result_length || (result_length != 0 && output == null)) { return -2; }
    for (usz i = 0; i < result_length; i++) { output[i] = (char)result[i]; }
    return (long)result_length;
}
