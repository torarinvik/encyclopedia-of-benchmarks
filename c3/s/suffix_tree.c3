module suffix_tree;

const usz MAX_TEXT_LENGTH = 64;
const usz MAX_VALID_INPUT_LENGTH = 65;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1;
const usz MAX_TREE_NODES = 1 + 2 * MAX_TEXT_LENGTH;
const usz MAX_TREE_EDGES = 2 * MAX_TEXT_LENGTH;
const usz MAX_OUTPUT_BYTES = MAX_TEXT_LENGTH * (MAX_TEXT_LENGTH + 1) / 2 +
                             48 * MAX_TEXT_LENGTH + 24;

fn bool write_u64_le(char* buffer, usz capacity, usz* offset, long value) {
    if (*offset > capacity || capacity - *offset < 8) return false;
    for (usz byte = 0; byte < 8; byte++) {
        buffer[*offset] = (char)(value & 255);
        *offset += 1;
        value >>= 8;
    }
    return true;
}

fn bool append_child_edge(usz* first_edge, usz* last_edge, usz* child_count,
                          usz* edge_target, usz* next_edge, usz* edge_count,
                          usz parent, usz child) {
    if (*edge_count >= MAX_TREE_EDGES) return false;
    *edge_count += 1;
    usz edge = *edge_count;
    edge_target[edge] = child;
    next_edge[edge] = 0;
    if (child_count[parent] == 0) {
        first_edge[parent] = edge;
    } else {
        next_edge[last_edge[parent]] = edge;
    }
    last_edge[parent] = edge;
    child_count[parent] += 1;
    return true;
}

fn long suffix_tree_construct(long* input, usz input_length, char* output,
                              usz output_capacity) @export("suffix_tree_construct") {
    if (input == null || input_length < 1 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH) return -1;
    usz text_length = (usz)input[0];
    if (input_length != 1 + text_length) return -1;
    for (usz i = 0; i < text_length; i++) {
        if (input[1 + i] < 0 || input[1 + i] > 127) return -1;
    }

    usz[MAX_TREE_NODES] label_start = zeroed;
    usz[MAX_TREE_NODES] label_length = zeroed;
    usz[MAX_TREE_NODES] first_edge = zeroed;
    usz[MAX_TREE_NODES] last_edge = zeroed;
    usz[MAX_TREE_NODES] child_count = zeroed;
    usz[MAX_TREE_EDGES + 1] edge_target = zeroed;
    usz[MAX_TREE_EDGES + 1] next_edge = zeroed;
    usz node_count = 1;
    usz edge_count = 0;

    for (usz suffix_start = 0; suffix_start < text_length; suffix_start++) {
        usz suffix_length = text_length - suffix_start;
        usz node = 0;
        usz offset = 0;
        while (offset < suffix_length) {
            long first_code = input[1 + suffix_start + offset];
            usz edge = first_edge[node];
            while (edge != 0 &&
                   input[1 + label_start[edge_target[edge]]] != first_code) {
                edge = next_edge[edge];
            }

            if (edge == 0) {
                if (node_count >= MAX_TREE_NODES) return -1;
                usz leaf = node_count;
                node_count += 1;
                label_start[leaf] = suffix_start + offset;
                label_length[leaf] = suffix_length - offset;
                if (!append_child_edge(&first_edge[0], &last_edge[0], &child_count[0],
                                       &edge_target[0], &next_edge[0], &edge_count,
                                       node, leaf)) return -1;
                break;
            }

            usz child = edge_target[edge];
            usz old_label_start = label_start[child];
            usz old_label_length = label_length[child];
            usz common = 0;
            while (common < old_label_length) {
                if (offset + common >= suffix_length ||
                    input[1 + suffix_start + offset + common] !=
                        input[1 + old_label_start + common]) {
                    if (node_count >= MAX_TREE_NODES) return -1;
                    usz split_node = node_count;
                    node_count += 1;
                    label_start[split_node] = old_label_start;
                    label_length[split_node] = common;
                    label_start[child] = old_label_start + common;
                    label_length[child] = old_label_length - common;
                    edge_target[edge] = split_node;
                    if (!append_child_edge(&first_edge[0], &last_edge[0], &child_count[0],
                                           &edge_target[0], &next_edge[0], &edge_count,
                                           split_node, child)) return -1;
                    child = split_node;
                    break;
                }
                common += 1;
            }

            offset += common;
            node = child;
        }
    }

    char[MAX_OUTPUT_BYTES] staged = zeroed;
    usz staged_length = 0;
    if (!write_u64_le(&staged[0], MAX_OUTPUT_BYTES, &staged_length,
                      (long)node_count)) return -1;
    for (usz node = 0; node < node_count; node++) {
        if (!write_u64_le(&staged[0], MAX_OUTPUT_BYTES, &staged_length,
                          (long)label_length[node])) return -1;
        if (label_length[node] > MAX_OUTPUT_BYTES - staged_length) return -1;
        for (usz byte = 0; byte < label_length[node]; byte++) {
            staged[staged_length + byte] = (char)input[1 + label_start[node] + byte];
        }
        staged_length += label_length[node];
        if (!write_u64_le(&staged[0], MAX_OUTPUT_BYTES, &staged_length,
                          (long)child_count[node])) return -1;
        usz edge = first_edge[node];
        while (edge != 0) {
            if (!write_u64_le(&staged[0], MAX_OUTPUT_BYTES, &staged_length,
                              (long)edge_target[edge])) return -1;
            edge = next_edge[edge];
        }
    }

    if (output == null || output_capacity < staged_length) return -2;
    for (usz byte = 0; byte < staged_length; byte++) output[byte] = staged[byte];
    return (long)staged_length;
}
