module transitive_closure_reflexive_matrix;

const usz MAX_VERTICES = 32;
const usz MAX_EDGES = MAX_VERTICES * (MAX_VERTICES - 1);
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES;
const usz MAX_CELLS = MAX_VERTICES * MAX_VERTICES;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long transitive_closure_reflexive_matrix(long* input, usz length, char* output, usz capacity)
    @export("transitive_closure_reflexive_matrix") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES) return -1;
    usz n = (usz)input[0];
    if (input[1] < 0 || input[1] > (long)(n * (n - 1))) return -1;
    usz m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;

    long[MAX_CELLS] reach;
    for (usz index = 0; index < MAX_CELLS; index++) reach[index] = 0;
    for (usz i = 0; i < n; i++) reach[i * n + i] = 1;
    for (usz edge = 0; edge < m; edge++) {
        long from_value = input[2 + 2 * edge], to_value = input[3 + 2 * edge];
        if (from_value < 0 || from_value >= (long)n || to_value < 0 || to_value >= (long)n || from_value == to_value) return -1;
        usz from = (usz)from_value, to = (usz)to_value;
        if (reach[from * n + to] != 0) return -1;
        reach[from * n + to] = 1;
    }
    for (usz k = 0; k < n; k++)
        for (usz i = 0; i < n; i++)
            if (reach[i * n + k] == 1)
                for (usz j = 0; j < n; j++)
                    if (reach[k * n + j] == 1) reach[i * n + j] = 1;

    usz output_bytes = n * n * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < n * n; index++) put_i64_le(output, index * 8, reach[index]);
    return (long)output_bytes;
}
