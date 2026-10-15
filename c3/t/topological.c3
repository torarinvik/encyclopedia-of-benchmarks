module topological;

// Source-faithful port of TheAlgorithms/Go graph.Topological.
fn long topological(long* values, usz length, char* output, usz output_capacity)
    @export("topological")
{
    if (values == null || length < 1 || length > 66 || (length - 1) % 2 != 0) return -2;
    if (values[0] < 0 || values[0] > 64) return -2;
    usz vertices = (usz)values[0];
    usz edge_count = (length - 1) / 2;
    char[64] dependencies;
    ulong[64] adjacency;
    char[96] answer;
    for (usz vertex = 0; vertex < 64; vertex++) {
        dependencies[vertex] = 0;
        adjacency[vertex] = 0ul;
    }

    for (usz edge = 0; edge < edge_count; edge++) {
        long origin_value = values[1 + 2 * edge];
        long destination_value = values[2 + 2 * edge];
        if (origin_value < 0 || destination_value < 0 ||
            (ulong)origin_value >= (ulong)vertices || (ulong)destination_value >= (ulong)vertices) return -2;
        usz origin = (usz)origin_value;
        usz destination = (usz)destination_value;
        dependencies[destination] += 1;
        adjacency[origin] = adjacency[origin] | (1ul << (ulong)destination);
    }

    usz answer_count = 0;
    for (usz root = 0; root < vertices; root++) {
        if (dependencies[root] != 0) continue;
        usz[64] stack;
        usz top = 0;
        stack[top] = root;
        top += 1;
        while (top > 0) {
            top -= 1;
            usz origin = stack[top];
            answer[answer_count] = (char)origin;
            answer_count += 1;
            for (usz destination = 0; destination < vertices; destination++) {
                ulong edge_mask = 1ul << (ulong)destination;
                if ((adjacency[origin] & edge_mask) != 0ul) {
                    bool in_stack = false;
                    for (usz index = 0; index < top; index++) {
                        if (stack[index] == destination) {
                            in_stack = true;
                            break;
                        }
                    }
                    if (!in_stack) {
                        stack[top] = destination;
                        top += 1;
                    }
                }
                adjacency[origin] = adjacency[origin] & ~edge_mask;
                adjacency[destination] = adjacency[destination] & ~(1ul << (ulong)origin);
            }
        }
    }

    if (output_capacity < answer_count || (answer_count != 0 && output == null)) return -2;
    for (usz index = 0; index < answer_count; index++) output[index] = answer[index];
    return (long)answer_count;
}
