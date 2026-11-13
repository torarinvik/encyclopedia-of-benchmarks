#include <stddef.h>
#include <stdint.h>

enum { MAX_OPERATIONS = 32, QUEUE_CAPACITY = 16, MAX_PARSEABLE_LENGTH = 65 };
static const int64_t VALUE_MIN = -1000;
static const int64_t VALUE_MAX = 1000;
static const int64_t CHECKSUM_OFFSET = 1001;

int64_t minimum_queue_two_stacks(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;

    int64_t in_values[QUEUE_CAPACITY], in_minimums[QUEUE_CAPACITY];
    int64_t out_values[QUEUE_CAPACITY], out_minimums[QUEUE_CAPACITY];
    size_t in_count = 0, out_count = 0, cursor = 1;
    const size_t operation_count = (size_t)input[0];
    int64_t checksum = 0;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor >= length) return -1;
            const int64_t value = input[cursor++];
            if (value < VALUE_MIN || value > VALUE_MAX ||
                in_count + out_count >= QUEUE_CAPACITY) return -1;
            in_values[in_count] = value;
            in_minimums[in_count] = in_count == 0 || value < in_minimums[in_count - 1]
                ? value : in_minimums[in_count - 1];
            ++in_count;
        } else if (opcode == 1) {
            if (in_count + out_count == 0) return -1;
            if (out_count == 0) {
                while (in_count > 0) {
                    const int64_t value = in_values[--in_count];
                    out_values[out_count] = value;
                    out_minimums[out_count] = out_count == 0 || value < out_minimums[out_count - 1]
                        ? value : out_minimums[out_count - 1];
                    ++out_count;
                }
            }
            const int64_t observed = out_values[--out_count];
            checksum += (int64_t)(operation + 1) * (observed + CHECKSUM_OFFSET);
        } else if (opcode == 2) {
            if (in_count + out_count == 0) return -1;
            int64_t observed;
            if (in_count == 0) observed = out_minimums[out_count - 1];
            else if (out_count == 0) observed = in_minimums[in_count - 1];
            else observed = in_minimums[in_count - 1] < out_minimums[out_count - 1]
                ? in_minimums[in_count - 1] : out_minimums[out_count - 1];
            checksum += (int64_t)(operation + 1) * (observed + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    size_t position = 0;
    for (size_t index = out_count; index > 0; --index) {
        ++position;
        checksum += (int64_t)position * (out_values[index - 1] + CHECKSUM_OFFSET);
    }
    for (size_t index = 0; index < in_count; ++index) {
        ++position;
        checksum += (int64_t)position * (in_values[index] + CHECKSUM_OFFSET);
    }
    return checksum;
}
