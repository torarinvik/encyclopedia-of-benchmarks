module llubenchmark_list_traversal_growth;

const int MAX_LISTS = 4;
const int MAX_INITIAL_LENGTH = 4;
const int MAX_ITERATIONS = 16;
const int MAX_NODES = 36;

fn void store_le_i64(uchar* output, usz offset, long value) {
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = ((value >> (8 * byte)) & 255).uchar();
    }
}

fn long llubenchmark_list_traversal_growth(long* input, usz input_length,
        uchar* output, usz output_capacity)
    @export("llubenchmark_list_traversal_growth") {
    if (input == null || input_length != 3) return -1;
    long list_value = input[0];
    long initial_value = input[1];
    long iteration_value = input[2];
    if (list_value < 1 || list_value > MAX_LISTS ||
        initial_value < 1 || initial_value > MAX_INITIAL_LENGTH ||
        iteration_value < 0 || iteration_value > MAX_ITERATIONS) return -1;
    if (output == null || output_capacity < 16) return -2;

    int list_count = list_value.int();
    int initial_length = initial_value.int();
    int iterations = iteration_value.int();
    [MAX_NODES]long next_node = zeroed;
    [MAX_NODES]long node_count = zeroed;
    [MAX_LISTS]long head = zeroed;
    [MAX_LISTS]long tail = zeroed;
    for (int i = 0; i < MAX_NODES; i++) { next_node[i] = -1; node_count[i] = 0; }
    for (int i = 0; i < MAX_LISTS; i++) { head[i] = -1; tail[i] = -1; }
    int allocated = 0;
    for (int level = 0; level < initial_length; level++) {
        for (int list = 0; list < list_count; list++) {
            int node = allocated;
            allocated++;
            next_node[node] = head[list];
            head[list] = node;
            if (tail[list] == -1) tail[list] = node;
        }
    }
    long accumulate = 0;
    int growth_milli = 0;
    for (int pass = 0; pass < iterations; pass++) {
        for (int list = 0; list < list_count; list++) {
            long node = head[list];
            while (node != -1) {
                accumulate += node_count[node];
                node_count[node]++;
                node = next_node[node];
            }
        }
        growth_milli += 333;
        int insertions = growth_milli / 1000;
        growth_milli -= insertions * 1000;
        for (int ordinal = insertions; ordinal > 0; ordinal--) {
            for (int list = 0; list < list_count; list++) {
                int node = allocated;
                allocated++;
                node_count[node] = list + ordinal;
                next_node[node] = -1;
                next_node[tail[list]] = node;
                tail[list] = node;
            }
        }
    }
    store_le_i64(output, 0, accumulate);
    store_le_i64(output, 8, allocated);
    return 2;
}
