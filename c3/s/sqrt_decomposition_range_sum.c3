module sqrt_decomposition_range_sum;

const MAX_N = 64;
const MAX_OPERATIONS = 64;
const MAX_INPUT_LENGTH = 258;

fn usz block_size_for(usz n) {
    usz block_size = 1;
    while ((block_size + 1) * (block_size + 1) <= n) block_size++;
    return block_size;
}

fn long query_sum(long* elements, long* blocks, usz block_size, usz start, usz end) {
    usz first_index_next_block = ((start / block_size) + 1) * block_size;
    long sum = elements[start];
    if (first_index_next_block > end) {
        for (usz index = start + 1; index < end; index++) sum += elements[index];
    } else {
        for (usz index = start + 1; index < first_index_next_block; index++) sum += elements[index];
        usz end_block = end / block_size;
        for (usz block = first_index_next_block / block_size; block < end_block; block++) sum += blocks[block];
        for (usz index = end_block * block_size; index < end; index++) sum += elements[index];
    }
    return sum;
}

fn long sqrt_decomposition_range_sum(long* input, usz length, char* output, usz capacity) @export("sqrt_decomposition_range_sum") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    if (length < n + 2) return -1;
    if (input[n + 1] < 0 || input[n + 1] > MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[n + 1];
    if (length != 2 + n + 3 * operation_count) return -1;

    long elements[MAX_N];
    for (usz index = 0; index < n; index++) {
        long value = input[index + 1];
        if (value < -1000 || value > 1000) return -1;
        elements[index] = value;
    }
    usz query_count = 0;
    usz operations_start = n + 2;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = operations_start + 3 * operation;
        long kind = input[offset];
        long first = input[offset + 1];
        long second = input[offset + 2];
        if (kind == 0) {
            if (first < 0 || first >= second || second > (long)n) return -1;
            query_count++;
        } else if (kind == 1) {
            if (first < 0 || first >= (long)n || second < -1000 || second > 1000) return -1;
        } else return -1;
    }

    usz output_bytes = query_count * 8;
    if (output == null || capacity < output_bytes) return -2;

    usz block_size = block_size_for(n);
    long blocks[MAX_N];
    for (usz index = 0; index < MAX_N; index++) blocks[index] = 0;
    for (usz index = 0; index < n; index++) {
        usz block = index / block_size;
        if (index % block_size == 0) blocks[block] = elements[index];
        else blocks[block] += elements[index];
    }

    usz output_offset = 0;
    for (usz operation = 0; operation < operation_count; operation++) {
        usz offset = operations_start + 3 * operation;
        long kind = input[offset];
        usz first = (usz)input[offset + 1];
        long second = input[offset + 2];
        if (kind == 0) {
            long sum = query_sum(elements, blocks, block_size, first, (usz)second);
            ulong bits = (ulong)sum;
            for (usz byte = 0; byte < 8; byte++) {
                output[output_offset++] = (char)(bits & 255);
                bits >>= 8;
            }
        } else {
            usz block = first / block_size;
            blocks[block] = blocks[block] - elements[first] + second;
            elements[first] = second;
        }
    }
    return (long)output_bytes;
}
