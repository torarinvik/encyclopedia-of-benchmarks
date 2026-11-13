module minimum_queue_two_stacks;

const long VALUE_MIN = -1000;
const long VALUE_MAX = 1000;
const long CHECKSUM_OFFSET = 1001;
const usz QUEUE_CAPACITY = 16;
const usz MAX_PARSEABLE_LENGTH = 65;

fn long minimum_queue_two_stacks(long* input, usz length)
        @export("minimum_queue_two_stacks") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 0 || input[0] > 32) return -1;

    long[QUEUE_CAPACITY] in_values;
    long[QUEUE_CAPACITY] in_minimums;
    long[QUEUE_CAPACITY] out_values;
    long[QUEUE_CAPACITY] out_minimums;
    usz in_count = 0, out_count = 0, cursor = 1;
    usz operation_count = (usz)input[0];
    long checksum = 0;

    for (usz operation = 0; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        long opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor >= length) return -1;
            long value = input[cursor++];
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
                    long value = in_values[--in_count];
                    out_values[out_count] = value;
                    out_minimums[out_count] = out_count == 0 || value < out_minimums[out_count - 1]
                        ? value : out_minimums[out_count - 1];
                    ++out_count;
                }
            }
            long observed = out_values[--out_count];
            checksum += (long)(operation + 1) * (observed + CHECKSUM_OFFSET);
        } else if (opcode == 2) {
            if (in_count + out_count == 0) return -1;
            long observed;
            if (in_count == 0) observed = out_minimums[out_count - 1];
            else if (out_count == 0) observed = in_minimums[in_count - 1];
            else observed = in_minimums[in_count - 1] < out_minimums[out_count - 1]
                ? in_minimums[in_count - 1] : out_minimums[out_count - 1];
            checksum += (long)(operation + 1) * (observed + CHECKSUM_OFFSET);
        } else return -1;
    }
    if (cursor != length) return -1;

    usz position = 0;
    for (usz index = out_count; index > 0; --index) {
        ++position;
        checksum += (long)position * (out_values[index - 1] + CHECKSUM_OFFSET);
    }
    for (usz index = 0; index < in_count; ++index) {
        ++position;
        checksum += (long)position * (in_values[index] + CHECKSUM_OFFSET);
    }
    return checksum;
}
