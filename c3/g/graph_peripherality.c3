module graph_peripherality;
const int MAX_VERTICES = 8;
const int MAX_EDGES = 56;
const long INF = 2305843009213693951;

fn void put64(long value, char* output, usz word) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[word * 8 + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long graph_peripherality(long* input, usz length, char* output, usz capacity) @export("graph_peripherality") {
    if (input == null || length < 2) return -1;
    long n_value = input[0], edge_value = input[1];
    if (n_value < 1 || n_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES ||
        edge_value > n_value * (n_value - 1) || length != 2 + 3 * (usz)edge_value) return -1;
    int n = (int)n_value, edge_count = (int)edge_value;
    long[MAX_VERTICES][MAX_VERTICES] distance;
    for (int i = 0; i < n; i++) for (int j = 0; j < n; j++) distance[i][j] = i == j ? 0 : INF;
    for (int edge = 0; edge < edge_count; edge++) {
        long source_value = input[2 + 3 * edge], destination_value = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (source_value < 0 || source_value >= n || destination_value < 0 || destination_value >= n ||
            source_value == destination_value || weight < 1 || weight > 1000000) return -1;
        int source = (int)source_value, destination = (int)destination_value;
        if (distance[source][destination] != INF) return -1;
        distance[source][destination] = weight;
    }
    for (int middle = 0; middle < n; middle++) for (int source = 0; source < n; source++) {
        if (distance[source][middle] == INF) continue;
        for (int destination = 0; destination < n; destination++)
            if (distance[middle][destination] != INF && distance[source][middle] + distance[middle][destination] < distance[source][destination])
                distance[source][destination] = distance[source][middle] + distance[middle][destination];
    }
    if (n > 1) {
        for (int source = 0; source < n; source++) for (int destination = 0; destination < n; destination++)
            if (source != destination && distance[source][destination] == INF) return -1;
    }
    int peripheral = -1, far = -1, peripheral_infinite = 0, far_infinite = 0, any_reachable = 0;
    long best_eccentricity = -1, best_farness = -1;
    if (n == 1) { peripheral = 0; far = 0; best_eccentricity = 0; best_farness = 0; }
    else { for (int source = 0; source < n; source++) {
        int found = 0;
        long eccentricity = 0, farness = 0;
        for (int destination = 0; destination < n; destination++) {
            long value = distance[source][destination];
            if (destination == source || value == INF || value == 0) continue;
            found = 1;
            if (value > eccentricity) eccentricity = value;
            farness += value;
        }
        if (found) any_reachable = 1;
        int infinite = !found;
        if (peripheral < 0 || (infinite && !peripheral_infinite) || (infinite == peripheral_infinite &&
            (infinite || eccentricity > best_eccentricity || (eccentricity == best_eccentricity && source < peripheral)))) {
            peripheral = source; peripheral_infinite = infinite; best_eccentricity = eccentricity;
        }
        if (far < 0 || (infinite && !far_infinite) || (infinite == far_infinite &&
            (infinite || farness > best_farness || (farness == best_farness && source < far)))) {
            far = source; far_infinite = infinite; best_farness = farness;
        }
    } }
    if (n > 1) {
        if (!any_reachable) { peripheral = -1; far = -1; best_eccentricity = -1; best_farness = -1; }
        else { if (peripheral_infinite) best_eccentricity = -1; if (far_infinite) best_farness = -1; }
    }
    if (output == null || capacity < 32) return -2;
    put64((long)peripheral, output, 0); put64(best_eccentricity, output, 1);
    put64((long)far, output, 2); put64(best_farness, output, 3);
    return 32;
}
