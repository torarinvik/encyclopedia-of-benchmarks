/* Bounded command trace for the pinned C# Timeline<TValue> collection. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INITIAL_EVENTS 16
#define MAX_COMMANDS 32
#define MAX_EVENTS (MAX_INITIAL_EVENTS + MAX_COMMANDS)
#define MAX_VALID_INPUT_LENGTH (2 + 2 * MAX_INITIAL_EVENTS + 3 * MAX_COMMANDS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define MAX_OUTPUT_WORDS 691
#define MAX_OUTPUT_BYTES (8 * MAX_OUTPUT_WORDS)

static void push_word(int64_t *words, size_t *count, int64_t value)
{
    words[*count] = value;
    ++*count;
}

int64_t timeline(const int64_t *input, size_t input_length,
                 uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_INITIAL_EVENTS) return -1;
    const size_t initial_count = (size_t)input[0];
    const size_t command_count_index = 1 + 2 * initial_count;
    if (command_count_index >= input_length) return -1;
    if (input[command_count_index] < 0 || input[command_count_index] > MAX_COMMANDS) return -1;
    const size_t command_count = (size_t)input[command_count_index];
    if (input_length != 2 + 2 * initial_count + 3 * command_count) return -1;

    int64_t event_times[MAX_EVENTS] = {0};
    int64_t event_values[MAX_EVENTS] = {0};
    int64_t operations[MAX_COMMANDS] = {0};
    int64_t first_arguments[MAX_COMMANDS] = {0};
    int64_t second_arguments[MAX_COMMANDS] = {0};
    size_t event_count = initial_count;
    for (size_t index = 0; index < initial_count; ++index) {
        const int64_t time = input[1 + 2 * index];
        const int64_t value = input[2 + 2 * index];
        if (time < 0 || time > 1000000 || value < -32 || value > 32) return -1;
        event_times[index] = time;
        event_values[index] = value;
    }
    /* Stable insertion sort matches the constructor's OrderBy. */
    for (size_t index = 1; index < initial_count; ++index) {
        const int64_t time = event_times[index];
        const int64_t value = event_values[index];
        size_t position = index;
        while (position > 0 && event_times[position - 1] > time) {
            event_times[position] = event_times[position - 1];
            event_values[position] = event_values[position - 1];
            --position;
        }
        event_times[position] = time;
        event_values[position] = value;
    }

    size_t offset = command_count_index + 1;
    for (size_t index = 0; index < command_count; ++index) {
        const int64_t opcode = input[offset];
        const int64_t first = input[offset + 1];
        const int64_t second = input[offset + 2];
        if (opcode < 0 || opcode > 14) return -1;
        if (opcode <= 2) {
            if (first < 0 || first > 1000000 || second < -32 || second > 32) return -1;
        } else if (opcode == 3 || opcode == 4 || opcode == 5 || opcode == 6 || opcode == 8) {
            if (first < 0 || first > 1000000 || second != 0) return -1;
        } else if (opcode == 7 || opcode == 9) {
            if (first < -32 || first > 32 || second != 0) return -1;
        } else if (first != 0 || second != 0) {
            return -1;
        }
        operations[index] = opcode;
        first_arguments[index] = first;
        second_arguments[index] = second;
        offset += 3;
    }

    int64_t words[MAX_OUTPUT_WORDS] = {0};
    size_t word_count = 0;
    for (size_t command = 0; command < command_count; ++command) {
        const int64_t opcode = operations[command];
        const int64_t first = first_arguments[command];
        const int64_t second = second_arguments[command];
        const size_t count_index = word_count + 1;
        push_word(words, &word_count, opcode);
        push_word(words, &word_count, 0);

        if (opcode == 0) {
            event_times[event_count] = first;
            event_values[event_count] = second;
            ++event_count;
        } else if (opcode == 1) {
            int found = 0;
            for (size_t index = 0; index < event_count; ++index)
                if (event_times[index] == first && event_values[index] == second) found = 1;
            push_word(words, &word_count, found);
        } else if (opcode == 2) {
            size_t found = event_count;
            for (size_t index = 0; index < event_count; ++index) {
                if (event_times[index] == first && event_values[index] == second) {
                    found = index;
                    break;
                }
            }
            if (found < event_count) {
                for (size_t index = found + 1; index < event_count; ++index) {
                    event_times[index - 1] = event_times[index];
                    event_values[index - 1] = event_values[index];
                }
                --event_count;
                push_word(words, &word_count, 1);
            } else {
                push_word(words, &word_count, 0);
            }
        } else if (opcode == 3) {
            for (size_t index = 0; index < event_count; ++index)
                if (event_times[index] == first) push_word(words, &word_count, event_values[index]);
        } else if (opcode == 4 || opcode == 5 || opcode == 10 || opcode == 12) {
            int64_t unique[MAX_EVENTS] = {0};
            size_t unique_count = 0;
            for (size_t index = 0; index < event_count; ++index) {
                int seen = 0;
                for (size_t prior = 0; prior < index; ++prior)
                    if (event_times[prior] == event_times[index]) seen = 1;
                if (!seen && (opcode == 10 || opcode == 12 ||
                    (opcode == 4 && event_times[index] < first) ||
                    (opcode == 5 && event_times[index] > first)))
                    unique[unique_count++] = event_times[index];
            }
            if (opcode == 4 || opcode == 5) {
                for (size_t index = 1; index < unique_count; ++index) {
                    const int64_t value = unique[index];
                    size_t position = index;
                    while (position > 0 && unique[position - 1] > value) {
                        unique[position] = unique[position - 1];
                        --position;
                    }
                    unique[position] = value;
                }
            }
            if (opcode == 12) push_word(words, &word_count, (int64_t)unique_count);
            else for (size_t index = 0; index < unique_count; ++index)
                push_word(words, &word_count, unique[index]);
        } else if (opcode == 6 || opcode == 7) {
            const int by_time = opcode == 6;
            int existed = 0;
            size_t write = 0;
            for (size_t index = 0; index < event_count; ++index) {
                const int matches = by_time ? event_times[index] == first : event_values[index] == first;
                if (matches) existed = 1;
                else {
                    event_times[write] = event_times[index];
                    event_values[write] = event_values[index];
                    ++write;
                }
            }
            event_count = write;
            push_word(words, &word_count, existed);
        } else if (opcode == 8 || opcode == 9) {
            int found = 0;
            for (size_t index = 0; index < event_count; ++index)
                if ((opcode == 8 && event_times[index] == first) ||
                    (opcode == 9 && event_values[index] == first)) found = 1;
            push_word(words, &word_count, found);
        } else if (opcode == 11) {
            for (size_t index = 0; index < event_count; ++index)
                push_word(words, &word_count, event_values[index]);
        } else if (opcode == 13) {
            push_word(words, &word_count, (int64_t)event_count);
        } else { /* Clear */
            event_count = 0;
        }
        words[count_index] = (int64_t)(word_count - count_index - 1);
    }

    push_word(words, &word_count, -1);
    push_word(words, &word_count, (int64_t)event_count);
    for (size_t index = 0; index < event_count; ++index) {
        push_word(words, &word_count, event_times[index]);
        push_word(words, &word_count, event_values[index]);
    }
    const size_t output_bytes = word_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < word_count; ++index) {
        const uint64_t bits = (uint64_t)words[index];
        for (size_t byte = 0; byte < 8; ++byte)
            output[index * 8 + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)output_bytes;
}
