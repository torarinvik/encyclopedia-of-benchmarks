module graph_adjacency_matrix;
const int MAX_VERTICES = 8;
const int MAX_VERTEX_ID_EXCLUSIVE = 32;
const int MAX_EDGES = 64;
const int MAX_OPERATIONS = 24;

fn void put_i64(long value, char* output, usz word) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[word * 8 + byte] = (char)(bits & 255); bits >>= 8; }
}
fn int vertex_index(int* vertices, int count, int value) {
    for (int i = 0; i < count; i++) if (vertices[i] == value) return i;
    return -1;
}
fn void remove_vertex(int* vertices, int* matrix, int* count, int index) {
    int old_count = *count;
    for (int row = index; row + 1 < old_count; row++) {
        vertices[row] = vertices[row + 1];
        for (int column = 0; column < old_count; column++) matrix[row * MAX_VERTICES + column] = matrix[(row + 1) * MAX_VERTICES + column];
    }
    for (int row = 0; row + 1 < old_count; row++)
        for (int column = index; column + 1 < old_count; column++) matrix[row * MAX_VERTICES + column] = matrix[row * MAX_VERTICES + column + 1];
    for (int i = 0; i < old_count; i++) { matrix[(old_count - 1) * MAX_VERTICES + i] = 0; matrix[i * MAX_VERTICES + old_count - 1] = 0; }
    *count = old_count - 1;
}

fn long graph_adjacency_matrix(long* input, usz length, char* output, usz capacity) @export("graph_adjacency_matrix") {
    if (input == null || length < 4) return -1;
    long directed_value = input[0], vertex_count_value = input[1];
    if ((directed_value != 0 && directed_value != 1) || vertex_count_value < 0 || vertex_count_value > MAX_VERTICES) return -1;
    int directed = (int)directed_value, vertex_count = (int)vertex_count_value;
    if (length < (usz)(3 + vertex_count)) return -1;

    int[MAX_VERTICES] vertices;
    int[MAX_VERTICES * MAX_VERTICES] matrix;
    usz position = 2;
    for (int i = 0; i < vertex_count; i++) {
        long value = input[position++];
        if (value < 0 || value >= MAX_VERTEX_ID_EXCLUSIVE || vertex_index(&vertices[0], i, (int)value) >= 0) return -1;
        vertices[i] = (int)value;
    }
    if (position >= length) return -1;
    long edge_count_value = input[position++];
    if (edge_count_value < 0 || edge_count_value > MAX_EDGES || length < position + 2 * (usz)edge_count_value + 1) return -1;
    for (int edge = 0; edge < (int)edge_count_value; edge++) {
        long source_value = input[position++], destination_value = input[position++];
        if (source_value < 0 || source_value >= MAX_VERTEX_ID_EXCLUSIVE || destination_value < 0 || destination_value >= MAX_VERTEX_ID_EXCLUSIVE) return -1;
        int source = vertex_index(&vertices[0], vertex_count, (int)source_value);
        int destination = vertex_index(&vertices[0], vertex_count, (int)destination_value);
        if (source < 0 || destination < 0 || matrix[source * MAX_VERTICES + destination] != 0) return -1;
        matrix[source * MAX_VERTICES + destination] = 1;
        if (!directed) matrix[destination * MAX_VERTICES + source] = 1;
    }
    long operation_count_value = input[position++];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS || length != position + 3 * (usz)operation_count_value) return -1;
    int operation_count = (int)operation_count_value;
    int[MAX_OPERATIONS] results;

    for (int operation_index = 0; operation_index < operation_count; operation_index++) {
        long operation = input[position++], a_value = input[position++], b_value = input[position++];
        if (operation == 0) {
            if (a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0 || vertex_index(&vertices[0], vertex_count, (int)a_value) >= 0 || vertex_count >= MAX_VERTICES) return -1;
            for (int i = 0; i < MAX_VERTICES; i++) { matrix[i * MAX_VERTICES + vertex_count] = 0; matrix[vertex_count * MAX_VERTICES + i] = 0; }
            vertices[vertex_count++] = (int)a_value;
            results[operation_index] = 1;
        } else if (operation == 1) {
            if (a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0) return -1;
            int removed = vertex_index(&vertices[0], vertex_count, (int)a_value);
            if (removed < 0) return -1;
            remove_vertex(&vertices[0], &matrix[0], &vertex_count, removed);
            results[operation_index] = 1;
        } else if (operation == 2 || operation == 3 || operation == 5) {
            if (a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value < 0 || b_value >= MAX_VERTEX_ID_EXCLUSIVE) return -1;
            int source = vertex_index(&vertices[0], vertex_count, (int)a_value);
            int destination = vertex_index(&vertices[0], vertex_count, (int)b_value);
            if (source < 0 || destination < 0) return -1;
            int cell = source * MAX_VERTICES + destination;
            bool present = matrix[cell] != 0;
            if (operation == 5) { if (present) results[operation_index] = 1; else results[operation_index] = 0; }
            else if (operation == 2) {
                if (present) return -1;
                matrix[cell] = 1;
                if (!directed) matrix[destination * MAX_VERTICES + source] = 1;
                results[operation_index] = 1;
            } else {
                if (!present) return -1;
                matrix[cell] = 0;
                if (!directed) matrix[destination * MAX_VERTICES + source] = 0;
                results[operation_index] = 1;
            }
        } else if (operation == 4) {
            if (a_value < 0 || a_value >= MAX_VERTEX_ID_EXCLUSIVE || b_value != 0) return -1;
            if (vertex_index(&vertices[0], vertex_count, (int)a_value) >= 0) results[operation_index] = 1; else results[operation_index] = 0;
        } else if (operation == 6) {
            if (a_value != 0 || b_value != 0) return -1;
            vertex_count = 0;
            for (int i = 0; i < MAX_VERTICES * MAX_VERTICES; i++) matrix[i] = 0;
            results[operation_index] = 1;
        } else return -1;
    }

    usz words = 2 + (usz)operation_count + (usz)vertex_count + (usz)(vertex_count * vertex_count);
    if (output == null || capacity < words * 8) return -2;
    usz word = 0;
    put_i64((long)operation_count, output, word++);
    for (int i = 0; i < operation_count; i++) put_i64((long)results[i], output, word++);
    put_i64((long)vertex_count, output, word++);
    for (int i = 0; i < vertex_count; i++) put_i64((long)vertices[i], output, word++);
    for (int row = 0; row < vertex_count; row++) for (int column = 0; column < vertex_count; column++) put_i64((long)matrix[row * MAX_VERTICES + column], output, word++);
    return (long)(words * 8);
}
