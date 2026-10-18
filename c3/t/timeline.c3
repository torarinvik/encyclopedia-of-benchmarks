module timeline;

const usz MAX_INITIAL_EVENTS = 16;
const usz MAX_COMMANDS = 32;
const usz MAX_EVENTS = 48;
const usz MAX_PARSEABLE_INPUT_LENGTH = 131;
const usz MAX_OUTPUT_WORDS = 691;
const usz MAX_OUTPUT_BYTES = 5528;

fn void push_word(long* words, usz* count, long value) {
    words[count[0]] = value;
    count[0]++;
}

fn long timeline(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("timeline") {
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[0] < 0 || input[0] > (long)MAX_INITIAL_EVENTS) return -1L;
    usz initial_count = (usz)input[0];
    usz command_count_index = 1 + 2 * initial_count;
    if (command_count_index >= input_length || input[command_count_index] < 0 ||
        input[command_count_index] > (long)MAX_COMMANDS) return -1L;
    usz command_count = (usz)input[command_count_index];
    if (input_length != 2 + 2 * initial_count + 3 * command_count) return -1L;

    long[MAX_EVENTS] event_times = zeroed;
    long[MAX_EVENTS] event_values = zeroed;
    long[MAX_COMMANDS] operations = zeroed;
    long[MAX_COMMANDS] first_arguments = zeroed;
    long[MAX_COMMANDS] second_arguments = zeroed;
    usz event_count = initial_count;
    for (usz index = 0; index < initial_count; index++) {
        long time = input[1 + 2 * index];
        long value = input[2 + 2 * index];
        if (time < 0 || time > 1000000 || value < -32 || value > 32) return -1L;
        event_times[index] = time;
        event_values[index] = value;
    }
    // Stable insertion sort matches the constructor's OrderBy.
    for (usz index = 1; index < initial_count; index++) {
        long time = event_times[index];
        long value = event_values[index];
        usz position = index;
        while (position > 0 && event_times[position - 1] > time) {
            event_times[position] = event_times[position - 1];
            event_values[position] = event_values[position - 1];
            position--;
        }
        event_times[position] = time;
        event_values[position] = value;
    }

    usz offset = command_count_index + 1;
    for (usz index = 0; index < command_count; index++) {
        long opcode = input[offset];
        long first = input[offset + 1];
        long second = input[offset + 2];
        if (opcode < 0 || opcode > 14) return -1L;
        if (opcode <= 2) {
            if (first < 0 || first > 1000000 || second < -32 || second > 32) return -1L;
        } else if (opcode == 3 || opcode == 4 || opcode == 5 || opcode == 6 || opcode == 8) {
            if (first < 0 || first > 1000000 || second != 0) return -1L;
        } else if (opcode == 7 || opcode == 9) {
            if (first < -32 || first > 32 || second != 0) return -1L;
        } else if (first != 0 || second != 0) return -1L;
        operations[index] = opcode;
        first_arguments[index] = first;
        second_arguments[index] = second;
        offset += 3;
    }

    long[MAX_OUTPUT_WORDS] words = zeroed;
    usz word_count = 0;
    for (usz command = 0; command < command_count; command++) {
        long opcode = operations[command];
        long first = first_arguments[command];
        long second = second_arguments[command];
        usz count_index = word_count + 1;
        push_word(&words[0], &word_count, opcode);
        push_word(&words[0], &word_count, 0);

        if (opcode == 0) {
            event_times[event_count] = first;
            event_values[event_count] = second;
            event_count++;
        } else if (opcode == 1) {
            bool found = false;
            for (usz index = 0; index < event_count; index++)
                if (event_times[index] == first && event_values[index] == second) found = true;
            push_word(&words[0], &word_count, found ? 1L : 0L);
        } else if (opcode == 2) {
            usz found = event_count;
            for (usz index = 0; index < event_count; index++) {
                if (event_times[index] == first && event_values[index] == second) {
                    found = index;
                    break;
                }
            }
            if (found < event_count) {
                for (usz index = found + 1; index < event_count; index++) {
                    event_times[index - 1] = event_times[index];
                    event_values[index - 1] = event_values[index];
                }
                event_count--;
                push_word(&words[0], &word_count, 1);
            } else push_word(&words[0], &word_count, 0);
        } else if (opcode == 3) {
            for (usz index = 0; index < event_count; index++)
                if (event_times[index] == first) push_word(&words[0], &word_count, event_values[index]);
        } else if (opcode == 4 || opcode == 5 || opcode == 10 || opcode == 12) {
            long[MAX_EVENTS] unique = zeroed;
            usz unique_count = 0;
            for (usz index = 0; index < event_count; index++) {
                bool seen = false;
                for (usz prior = 0; prior < index; prior++)
                    if (event_times[prior] == event_times[index]) seen = true;
                if (!seen && (opcode == 10 || opcode == 12 ||
                    (opcode == 4 && event_times[index] < first) ||
                    (opcode == 5 && event_times[index] > first)))
                    unique[unique_count++] = event_times[index];
            }
            if (opcode == 4 || opcode == 5) {
                for (usz index = 1; index < unique_count; index++) {
                    long value = unique[index];
                    usz position = index;
                    while (position > 0 && unique[position - 1] > value) {
                        unique[position] = unique[position - 1];
                        position--;
                    }
                    unique[position] = value;
                }
            }
            if (opcode == 12) push_word(&words[0], &word_count, (long)unique_count);
            else for (usz index = 0; index < unique_count; index++)
                push_word(&words[0], &word_count, unique[index]);
        } else if (opcode == 6 || opcode == 7) {
            bool by_time = opcode == 6;
            bool existed = false;
            usz write = 0;
            for (usz index = 0; index < event_count; index++) {
                bool matches = by_time ? event_times[index] == first : event_values[index] == first;
                if (matches) existed = true;
                else {
                    event_times[write] = event_times[index];
                    event_values[write] = event_values[index];
                    write++;
                }
            }
            event_count = write;
            push_word(&words[0], &word_count, existed ? 1L : 0L);
        } else if (opcode == 8 || opcode == 9) {
            bool found = false;
            for (usz index = 0; index < event_count; index++)
                if ((opcode == 8 && event_times[index] == first) ||
                    (opcode == 9 && event_values[index] == first)) found = true;
            push_word(&words[0], &word_count, found ? 1L : 0L);
        } else if (opcode == 11) {
            for (usz index = 0; index < event_count; index++)
                push_word(&words[0], &word_count, event_values[index]);
        } else if (opcode == 13) push_word(&words[0], &word_count, (long)event_count);
        else event_count = 0;

        words[count_index] = (long)(word_count - count_index - 1);
    }

    push_word(&words[0], &word_count, -1);
    push_word(&words[0], &word_count, (long)event_count);
    for (usz index = 0; index < event_count; index++) {
        push_word(&words[0], &word_count, event_times[index]);
        push_word(&words[0], &word_count, event_values[index]);
    }
    usz output_bytes = word_count * 8;
    if (output == null || output_capacity < output_bytes || output_bytes > MAX_OUTPUT_BYTES) return -2L;
    for (usz index = 0; index < word_count; index++) {
        ulong bits = (ulong)words[index];
        for (usz byte = 0; byte < 8; byte++) {
            output[index * 8 + byte] = (uint8)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)output_bytes;
}
