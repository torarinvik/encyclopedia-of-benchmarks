module hierholzer_eulerian_path;

const usz MAX_VERTICES = 16;
const usz MAX_EDGES = 48;
const usz MAX_INPUT_LENGTH = 98;
const usz MAX_ROUTE = 49;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long hierholzer_eulerian_path(long* input, usz length, char* output, usz capacity)
        @export("hierholzer_eulerian_path") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long vertex_count_value = input[0], edge_count_value = input[1];
    if (vertex_count_value < 0 || vertex_count_value > (long)MAX_VERTICES ||
        edge_count_value < 0 || edge_count_value > (long)MAX_EDGES) return -1;
    usz vertex_count = (usz)vertex_count_value, edge_count = (usz)edge_count_value;
    if (length != 2 + 2 * edge_count) return -1;

    int[MAX_VERTICES][MAX_EDGES] adjacency;
    usz[MAX_VERTICES] in_degree = zeroed, out_degree = zeroed;
    for (usz edge = 0; edge < edge_count; edge++) {
        long source_value = input[2 + 2 * edge], destination_value = input[3 + 2 * edge];
        if (source_value < 0 || source_value >= vertex_count_value ||
            destination_value < 0 || destination_value >= vertex_count_value) return -1;
        usz source = (usz)source_value, destination = (usz)destination_value;
        adjacency[source][out_degree[source]++] = (int)destination;
        in_degree[destination]++;
    }

    int[MAX_ROUTE] path;
    usz path_length = 0;
    if (vertex_count == 0) {
        path_length = 0;
    } else if (edge_count == 0) {
        path[0] = 0;
        path_length = 1;
    } else {
        int start = -1;
        usz start_count = 0, end_count = 0;
        bool degrees_valid = true;
        for (usz vertex = 0; vertex < vertex_count; vertex++) {
            long difference = (long)out_degree[vertex] - (long)in_degree[vertex];
            if (difference == 1) { start = (int)vertex; start_count++; }
            else if (difference == -1) end_count++;
            else if (difference < -1 || difference > 1) degrees_valid = false;
        }
        if (!((start_count == 1 && end_count == 1) ||
              (start_count == 0 && end_count == 0))) degrees_valid = false;
        if (degrees_valid && start < 0) {
            for (usz vertex = 0; vertex < vertex_count; vertex++) {
                if (out_degree[vertex] > 0) { start = (int)vertex; break; }
            }
        }

        bool connected = degrees_valid;
        if (connected) {
            bool[MAX_VERTICES] visited = zeroed;
            int[MAX_VERTICES] pending;
            usz pending_head = 0, pending_tail = 1;
            pending[0] = start;
            visited[(usz)start] = true;
            while (pending_head < pending_tail) {
                int current = pending[pending_head++];
                for (usz edge = 0; edge < out_degree[(usz)current]; edge++) {
                    usz next = (usz)adjacency[(usz)current][edge];
                    if (!visited[next]) { visited[next] = true; pending[pending_tail++] = (int)next; }
                }
                for (usz source = 0; source < vertex_count; source++) {
                    if (visited[source]) continue;
                    for (usz edge = 0; edge < out_degree[source]; edge++) {
                        if (adjacency[source][edge] == current) {
                            visited[source] = true;
                            pending[pending_tail++] = (int)source;
                            break;
                        }
                    }
                }
            }
            for (usz vertex = 0; vertex < vertex_count; vertex++)
                if (in_degree[vertex] + out_degree[vertex] > 0 && !visited[vertex]) connected = false;
        }

        if (connected) {
            usz[MAX_VERTICES] next_position = zeroed;
            int[MAX_ROUTE] stack, reverse_path;
            usz stack_size = 1, reverse_length = 0;
            stack[0] = start;
            while (stack_size > 0) {
                int current = stack[stack_size - 1];
                if (next_position[(usz)current] < out_degree[(usz)current]) {
                    int next = adjacency[(usz)current][next_position[(usz)current]++];
                    stack[stack_size++] = next;
                } else {
                    reverse_path[reverse_length++] = stack[--stack_size];
                }
            }
            if (reverse_length == edge_count + 1) {
                path_length = reverse_length;
                for (usz index = 0; index < path_length; index++)
                    path[index] = reverse_path[path_length - 1 - index];
            }
        }
    }

    usz output_bytes = 8 * (path_length + 1);
    if (output == null || capacity < output_bytes) return -2;
    write_i64_le(output, 0, (long)path_length);
    for (usz index = 0; index < path_length; index++)
        write_i64_le(output, 8 * (index + 1), (long)path[index]);
    return (long)output_bytes;
}
