#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 128
#define MAX_INPUT_LENGTH 257
#define INVALID_RESULT (-1)
#define OUTPUT_ERROR (-2)

int64_t stack_using_two_queues(const int64_t *input, size_t length,
                               uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS ||
        length != 1 + 2 * (size_t)input[0]) return INVALID_RESULT;

    int64_t queue_a[MAX_OPERATIONS], queue_b[MAX_OPERATIONS];
    int64_t tags[MAX_OPERATIONS], results[MAX_OPERATIONS];
    int64_t *main_queue = queue_a, *temp_queue = queue_b;
    size_t main_head = 0, main_tail = 0, record_count = 0;
    size_t position = 1;
    const size_t operation_count = (size_t)input[0];

    for (size_t op_index = 0; op_index < operation_count; ++op_index) {
        const int64_t opcode = input[position];
        const int64_t operand = input[position + 1];
        position += 2;
        if (opcode == 0) {
            if (operand < INT32_MIN || operand > INT32_MAX) return INVALID_RESULT;
            size_t temp_tail = 0;
            temp_queue[temp_tail++] = operand;
            while (main_head < main_tail) temp_queue[temp_tail++] = main_queue[main_head++];
            int64_t *swap = main_queue;
            main_queue = temp_queue;
            temp_queue = swap;
            main_head = 0;
            main_tail = temp_tail;
        } else if (opcode == 1) {
            if (operand != 0 || main_head == main_tail) return INVALID_RESULT;
            tags[record_count] = 0;
            results[record_count++] = main_queue[main_head++];
        } else if (opcode == 2) {
            if (operand != 0) return INVALID_RESULT;
            if (main_head == main_tail) {
                tags[record_count] = 1;
                results[record_count++] = 0;
            } else {
                tags[record_count] = 0;
                results[record_count++] = main_queue[main_head];
            }
        } else return INVALID_RESULT;
    }
    const size_t output_length = record_count * 16;
    if (output == NULL || output_capacity < output_length) return OUTPUT_ERROR;
    for (size_t i = 0; i < record_count; ++i) {
        const uint64_t words[2] = {(uint64_t)tags[i], (uint64_t)results[i]};
        for (size_t word = 0; word < 2; ++word)
            for (size_t byte = 0; byte < 8; ++byte)
                output[16 * i + 8 * word + byte] = (uint8_t)(words[word] >> (8 * byte));
    }
    return (int64_t)output_length;
}
