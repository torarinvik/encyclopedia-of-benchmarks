module memory_management_algorithms;

const usz MAX_BLOCK_COUNT = 16;
const usz MAX_PROCESS_COUNT = 32;
const usz MAX_INPUT_LENGTH = 52;
const usz MAX_OUTPUT_BYTES = 256;
const long NO_ALLOCATION = -255;

void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long memory_management_algorithms(long* input, usz length, char* output, usz capacity)
        @export("memory_management_algorithms") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long policy = input[0];
    long block_count_value = input[1];
    long process_count_value = input[2];
    if (policy < 0 || policy > 3 || block_count_value < 1 || block_count_value > (long)MAX_BLOCK_COUNT ||
        process_count_value < 0 || process_count_value > (long)MAX_PROCESS_COUNT) return -1;
    usz block_count = (usz)block_count_value;
    usz process_count = (usz)process_count_value;
    if (length != 3 + block_count + process_count) return -1;

    long[MAX_BLOCK_COUNT] blocks;
    long[MAX_PROCESS_COUNT] processes;
    for (usz index = 0; index < block_count; index += 1) {
        long size = input[3 + index];
        if (size < 1 || size > 10000) return -1;
        blocks[index] = size;
    }
    for (usz index = 0; index < process_count; index += 1) {
        long size = input[3 + block_count + index];
        if (size < 1 || size > 10000) return -1;
        processes[index] = size;
    }

    long[MAX_PROCESS_COUNT] allocations;
    long next_fit_counter = 0;
    for (usz process_index = 0; process_index < process_count; process_index += 1) {
        long process = processes[process_index];
        long selected = NO_ALLOCATION;
        if (policy == 0) {
            for (usz index = 0; index < block_count; index += 1) {
                if (blocks[index] >= process) { selected = (long)index; break; }
            }
        } else if (policy == 1) {
            long min_diff = blocks[0];
            for (usz index = 1; index < block_count; index += 1)
                if (blocks[index] > min_diff) min_diff = blocks[index];
            for (usz index = 0; index < block_count; index += 1) {
                long difference = blocks[index] - process;
                if (difference < min_diff && difference >= 0) {
                    min_diff = difference;
                    selected = (long)index;
                }
            }
        } else if (policy == 2) {
            usz best = 0;
            for (usz candidate = 1; candidate < block_count; candidate += 1)
                if (blocks[candidate] > blocks[best]) best = candidate;
            if (blocks[best] >= process) selected = (long)best;
        } else {
            bool found = false;
            for (usz offset = 0; offset < block_count; offset += 1) {
                if (next_fit_counter + (long)offset >= (long)block_count)
                    next_fit_counter = -(long)offset;
                usz index = (usz)((long)offset + next_fit_counter);
                if (blocks[index] >= process) {
                    next_fit_counter += (long)offset;
                    selected = next_fit_counter;
                    found = true;
                    break;
                }
            }
            if (!found) next_fit_counter += (long)block_count;
        }
        allocations[process_index] = selected;
        if (selected != NO_ALLOCATION) blocks[(usz)selected] -= process;
    }

    usz output_bytes = process_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < process_count; index += 1) put_i64_le(output, index * 8, allocations[index]);
    return (long)output_bytes;
}
