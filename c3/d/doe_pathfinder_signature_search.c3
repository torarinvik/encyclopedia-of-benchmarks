module doe_pathfinder_signature_search;

const usz MAX_NODES = 10;
const usz MAX_EDGES = 100;
const usz MAX_SIGNATURE_LENGTH = 4;
const long MAX_LABEL = 7;

fn bool search_leg(long* values, usz edge_count, usz labels_start, usz signature_start,
                   usz signature_length, usz node, usz signature_index, long* visited) {
    long bit = (long)1 << node;
    if ((*visited & bit) != 0) return false;
    *visited |= bit;
    long target_label = values[signature_start + signature_index];

    for (usz edge = 0; edge < edge_count; edge++) {
        if ((usz)values[3 + 2 * edge] != node) continue;
        usz target = (usz)values[4 + 2 * edge];
        if (values[labels_start + target] != target_label) continue;
        if (signature_index + 1 == signature_length) return true;
        long next_visited = 0;
        if (search_leg(values, edge_count, labels_start, signature_start, signature_length,
                       target, signature_index + 1, &next_visited)) return true;
    }

    for (usz edge = 0; edge < edge_count; edge++) {
        if ((usz)values[3 + 2 * edge] != node) continue;
        usz target = (usz)values[4 + 2 * edge];
        if (search_leg(values, edge_count, labels_start, signature_start, signature_length,
                       target, signature_index, visited)) return true;
    }
    return false;
}

fn long doe_pathfinder_signature_search(long* values, usz length) @export("doe_pathfinder_signature_search") {
    if (values == null || length < 3 || values[0] < 1 || values[0] > (long)MAX_NODES ||
        values[1] < 0 || values[1] > (long)MAX_EDGES || values[2] < 2 ||
        values[2] > (long)MAX_SIGNATURE_LENGTH) return -2;
    usz node_count = (usz)values[0];
    usz edge_count = (usz)values[1];
    usz signature_length = (usz)values[2];
    if (edge_count > node_count * node_count ||
        length != 3 + 2 * edge_count + node_count + signature_length) return -2;

    for (usz edge = 0; edge < edge_count; edge++) {
        long from = values[3 + 2 * edge];
        long to = values[4 + 2 * edge];
        if (from < 0 || from >= (long)node_count || to < 0 || to >= (long)node_count) return -2;
        for (usz previous = 0; previous < edge; previous++)
            if (values[3 + 2 * previous] == from && values[4 + 2 * previous] == to) return -2;
    }
    usz labels_start = 3 + 2 * edge_count;
    usz signature_start = labels_start + node_count;
    for (usz node = 0; node < node_count; node++)
        if (values[labels_start + node] < -1 || values[labels_start + node] > MAX_LABEL) return -2;
    for (usz index = 0; index < signature_length; index++)
        if (values[signature_start + index] < 0 || values[signature_start + index] > MAX_LABEL) return -2;

    long first_label = values[signature_start];
    for (usz node = 0; node < node_count; node++) {
        if (values[labels_start + node] != first_label) continue;
        long visited = 0;
        if (search_leg(values, edge_count, labels_start, signature_start, signature_length,
                       node, 1, &visited)) return 1;
    }
    return 0;
}
