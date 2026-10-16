module depth_first_search_iterative_order;

const int MAX_VERTICES = 10;
const int MAX_EDGES = 64;
const int MAX_DEGREE = 2 * MAX_EDGES;

fn void put_i64(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[word * 8 + byte] = (char)((bits >> (byte * 8)) & 255);
    }
}

fn long depth_first_search_iterative_order(long* input, usz length,
    char* output, usz capacity) @export("depth_first_search_iterative_order") {
    if (input == null || length < 3) return -1;
    long n_value = input[0], edge_value = input[1];
    if (n_value < 1 || n_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES ||
        length != (usz)(3 + 2 * edge_value)) return -1;
    int n = (int)n_value;
    int[MAX_VERTICES + 1][MAX_DEGREE] adjacency;
    int[MAX_VERTICES + 1] degree;
    for (int edge = 0; edge < (int)edge_value; edge++) {
        long left_value = input[2 + 2 * edge], right_value = input[3 + 2 * edge];
        if (left_value < 1 || left_value > n || right_value < 1 || right_value > n) return -1;
        int left = (int)left_value, right = (int)right_value;
        adjacency[left][degree[left]++] = right;
        adjacency[right][degree[right]++] = left;
    }
    long start_value = input[length - 1];
    if (start_value < 1 || start_value > n) return -1;
    int[MAX_VERTICES] stack;
    int[MAX_VERTICES] order;
    bool[MAX_VERTICES + 1] visited;
    int stack_size = 0, order_count = 0, start = (int)start_value;
    visited[start] = true;
    stack[stack_size++] = start;
    while (stack_size > 0) {
        int vertex = stack[--stack_size];
        order[order_count++] = vertex;
        for (int edge = 0; edge < degree[vertex]; edge++) {
            int neighbor = adjacency[vertex][edge];
            if (!visited[neighbor]) {
                visited[neighbor] = true;
                stack[stack_size++] = neighbor;
            }
        }
    }
    usz words = (usz)order_count + 1;
    if (output == null || capacity < words * 8) return -2;
    put_i64(output, 0, (long)order_count);
    for (int index = 0; index < order_count; index++) put_i64(output, (usz)index + 1, (long)order[index]);
    return (long)(words * 8);
}
