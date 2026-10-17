module mo;

const usz MAX_N = 64;
const usz MAX_Q = 64;
const int MAX_VALUE = 255;
const usz MAX_PARSEABLE_INPUT_WORDS = 2 + MAX_N + 2 * MAX_Q + 1;
const usz MAX_OUTPUT_BYTES = 4 * MAX_Q;

struct Query { int left; int right; int index; }

fn int ceil_sqrt(int n) {
    int block = 1;
    while (block * block < n) block++;
    return block;
}

fn bool before(Query a, Query b, int block_size) {
    int a_block = a.left / block_size, b_block = b.left / block_size;
    if (a_block != b_block) return a_block < b_block;
    return a.right < b.right;
}

fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) { output[offset+byte] = (char)(bits & 255); bits >>= 8; }
}

long mo(int* input, usz length, char* output, usz capacity) @export("mo") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    int n_raw = input[0];
    if (n_raw < 1 || n_raw > (int)MAX_N) return -1;
    int n = n_raw, q_offset = 1 + n;
    if ((int)length <= q_offset) return -1;
    int q_raw = input[q_offset];
    if (q_raw < 0 || q_raw > (int)MAX_Q) return -1;
    int q_count = q_raw;
    if ((int)length != q_offset + 1 + 2*q_count) return -1;
    for (int i = 0; i < n; i++) if (input[1+i] < 0 || input[1+i] > MAX_VALUE) return -1;

    Query[MAX_Q] queries;
    for (int i = 0; i < q_count; i++) {
        int left_raw = input[q_offset+1+2*i], right_raw = input[q_offset+2+2*i];
        if (left_raw < 1 || right_raw < left_raw || right_raw > n) return -1;
        queries[i] = {left_raw-1, right_raw-1, i};
    }
    usz bytes = (usz)(4*q_count);
    if (output == null || capacity < bytes) return -2;
    int block_size = ceil_sqrt(n);
    for (int i = 1; i < q_count; i++) {
        Query value = queries[i];
        int j = i;
        while (j > 0 && before(value, queries[j-1], block_size)) { queries[j] = queries[j-1]; j--; }
        queries[j] = value;
    }
    int[MAX_VALUE+1] frequencies;
    int[MAX_Q] answers;
    int distinct = 0, left = 0, right = 0;
    for (int i = 0; i < q_count; i++) {
        Query query = queries[i];
        while (left < query.left) { int value = input[1+left]; left++; frequencies[value]--; if (frequencies[value] == 0) distinct--; }
        while (left > query.left) { left--; int value = input[1+left]; frequencies[value]++; if (frequencies[value] == 1) distinct++; }
        while (right <= query.right) { int value = input[1+right]; frequencies[value]++; if (frequencies[value] == 1) distinct++; right++; }
        while (right > query.right+1) { right--; int value = input[1+right]; frequencies[value]--; if (frequencies[value] == 0) distinct--; }
        answers[query.index] = distinct;
    }
    if (bytes == 0) return 0;
    char[MAX_OUTPUT_BYTES] buffer;
    for (int i = 0; i < q_count; i++) put_i32_le(&buffer[0], (usz)(i*4), answers[i]);
    for (usz i = 0; i < bytes; i++) output[i] = buffer[i];
    return (long)bytes;
}
