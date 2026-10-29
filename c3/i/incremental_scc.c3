module incremental_scc;

const usz MAX_VERTICES = 8;
const usz MAX_EDGES = 32;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES;
const usz REACHABILITY_CELLS = MAX_VERTICES * MAX_VERTICES;

fn long incremental_scc(long* input, usz length) @export("incremental_scc") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH || input[0] < 1 ||
        input[0] > (long)MAX_VERTICES || input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz vertex_count = (usz)input[0];
    usz edge_count = (usz)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    usz[MAX_EDGES] sources, destinations;
    for (usz edge = 0; edge < edge_count; edge++) {
        long source = input[2 + 2 * edge];
        long destination = input[3 + 2 * edge];
        if (source < 0 || destination < 0 || (ulong)source >= (ulong)vertex_count ||
            (ulong)destination >= (ulong)vertex_count) return -1;
        sources[edge] = (usz)source;
        destinations[edge] = (usz)destination;
    }

    bool[REACHABILITY_CELLS] reachable;
    for (usz cell = 0; cell < REACHABILITY_CELLS; cell++) reachable[cell] = false;
    for (usz vertex = 0; vertex < vertex_count; vertex++) reachable[vertex * MAX_VERTICES + vertex] = true;
    long checksum = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        usz source = sources[edge];
        usz destination = destinations[edge];
        bool[MAX_VERTICES] predecessors, successors;
        for (usz vertex = 0; vertex < vertex_count; vertex++) {
            predecessors[vertex] = reachable[vertex * MAX_VERTICES + source];
            successors[vertex] = reachable[destination * MAX_VERTICES + vertex];
        }
        for (usz first = 0; first < vertex_count; first++)
            for (usz second = 0; second < vertex_count; second++)
                if (predecessors[first] && successors[second])
                    reachable[first * MAX_VERTICES + second] = true;

        bool[MAX_VERTICES] assigned;
        for (usz vertex = 0; vertex < vertex_count; vertex++) assigned[vertex] = false;
        usz component_count = 0;
        for (usz first = 0; first < vertex_count; first++) {
            if (assigned[first]) continue;
            component_count++;
            for (usz vertex = first; vertex < vertex_count; vertex++)
                if (reachable[first * MAX_VERTICES + vertex] &&
                    reachable[vertex * MAX_VERTICES + first]) assigned[vertex] = true;
        }
        checksum += (long)(edge + 1) * (long)component_count;
    }
    return checksum;
}
