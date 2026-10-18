module undirected_adjacency_list_graph;

const usz MAX_NODES = 8;
const usz MAX_OPERATIONS = 24;
const usz MAX_PARSEABLE_INPUT_LENGTH = 98;
const usz MAX_OUTPUT_WORDS = 144;

fn void push_word(long* words, usz* count, long value) {
    words[count[0]] = value;
    count[0]++;
}

fn void push_record(long* words, usz* count, long opcode, long* payload, usz payload_count) {
    push_word(words, count, opcode);
    push_word(words, count, (long)payload_count);
    for (usz index = 0; index < payload_count; index++) push_word(words, count, payload[index]);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long undirected_adjacency_list_graph(long* input, usz input_length,
    char* output, usz output_capacity) @export("undirected_adjacency_list_graph") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[0] < 0 || input[0] > (long)MAX_OPERATIONS) return -1L;
    usz operation_count = (usz)input[0];
    if (input_length != 1 + 4 * operation_count) return -1L;

    long[MAX_OUTPUT_WORDS] words = zeroed;
    usz word_count = 0;
    long[MAX_NODES][MAX_NODES] edge_weights = zeroed;
    bool[MAX_NODES][MAX_NODES] has_edge = zeroed;
    usz node_count = 0;

    for (usz operation_index = 0; operation_index < operation_count; operation_index++) {
        usz base = 1 + 4 * operation_index;
        long opcode = input[base];
        long first = input[base + 1];
        long second = input[base + 2];
        long third = input[base + 3];
        if (opcode < 0 || opcode > 4) return -1L;

        if (opcode == 0 || opcode == 4) {
            if (first != 0 || second != 0 || third != 0) return -1L;
        } else if (opcode == 1) {
            if (first < -2147483648L || first > 2147483647L ||
                second < -2147483648L || second > 2147483647L ||
                third < -2147483648L || third > 2147483647L) return -1L;
        } else if (opcode == 2) {
            if (first < -2147483648L || first > 2147483647L || second != 0 || third != 0)
                return -1L;
        } else if (first < -2147483648L || first > 2147483647L ||
                   second < -2147483648L || second > 2147483647L || third != 0) {
            return -1L;
        }

        if (opcode == 0) {
            if (node_count >= MAX_NODES) return -1L;
            long[1] payload = {(long)node_count};
            push_record(&words[0], &word_count, opcode, &payload[0], 1);
            node_count++;
        } else if (opcode == 1) {
            bool added = false;
            if (first >= 0 && (ulong)first < node_count && second >= 0 &&
                (ulong)second < node_count && !has_edge[(usz)first][(usz)second]) {
                has_edge[(usz)first][(usz)second] = true;
                has_edge[(usz)second][(usz)first] = true;
                edge_weights[(usz)first][(usz)second] = third;
                edge_weights[(usz)second][(usz)first] = third;
                added = true;
            }
            long[1] payload = {added ? 1L : 0L};
            push_record(&words[0], &word_count, opcode, &payload[0], 1);
        } else if (opcode == 2) {
            if (first < 0 || (ulong)first >= node_count) return -1L;
            long[MAX_NODES + 1] payload = zeroed;
            usz neighbor_count = 0;
            for (usz neighbor = 0; neighbor < node_count; neighbor++) {
                if (has_edge[(usz)first][neighbor]) payload[neighbor_count++] = (long)neighbor;
            }
            for (usz index = neighbor_count; index > 0; index--) payload[index] = payload[index - 1];
            payload[0] = (long)neighbor_count;
            push_record(&words[0], &word_count, opcode, &payload[0], neighbor_count + 1);
        } else if (opcode == 3) {
            if (first < 0 || (ulong)first >= node_count) return -1L;
            bool present = second >= 0 && (ulong)second < node_count &&
                has_edge[(usz)first][(usz)second];
            long[2] payload = {present ? 1L : 0L,
                present ? edge_weights[(usz)first][(usz)second] : 0L};
            push_record(&words[0], &word_count, opcode, &payload[0], 2);
        } else {
            long[1] payload = {(long)node_count};
            push_record(&words[0], &word_count, opcode, &payload[0], 1);
        }
    }

    usz output_bytes = word_count * 8;
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz index = 0; index < word_count; index++)
        store_i64_le(output, index * 8, words[index]);
    return (long)output_bytes;
}
