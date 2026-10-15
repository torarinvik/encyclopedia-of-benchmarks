module count_and_say;

const MAX_TERM_INDEX = 19;
const MAX_TERM_LENGTH = 256;

fn long count_and_say(long term_index, char* output, usz output_capacity)
        @export("count_and_say") {
    if (term_index < 1 || term_index > MAX_TERM_INDEX) return -1;
    char[MAX_TERM_LENGTH] current;
    char[MAX_TERM_LENGTH] next;
    current[0] = '1';
    usz current_length = 1;
    for (long term = 1; term < term_index; term++) {
        usz next_length = 0;
        for (usz index = 0; index < current_length;) {
            usz end = index + 1;
            while (end < current_length && current[end] == current[index]) end++;
            usz run_length = end - index;
            if (next_length + 2 > MAX_TERM_LENGTH) return -1;
            next[next_length++] = (char)('0' + (long)run_length);
            next[next_length++] = current[index];
            index = end;
        }
        for (usz index = 0; index < next_length; index++) current[index] = next[index];
        current_length = next_length;
    }
    if (output_capacity < current_length || output == null) return -2;
    for (usz index = 0; index < current_length; index++) output[index] = current[index];
    return (long)current_length;
}
