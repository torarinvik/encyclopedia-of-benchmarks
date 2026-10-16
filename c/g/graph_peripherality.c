/* Bounded weighted directed graph peripherality and farness. */
#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#define MAX_VERTICES 8
#define MAX_EDGES 56
#define INF (INT64_MAX / 4)

static void put_i64(uint8_t *output, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[word * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t graph_peripherality(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2) return -1;
    int64_t n_value = input[0], edge_value = input[1];
    if (n_value < 1 || n_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES ||
        edge_value > n_value * (n_value - 1) || length != 2 + 3 * (size_t)edge_value) return -1;
    int n = (int)n_value, edge_count = (int)edge_value;
    int64_t distance[MAX_VERTICES][MAX_VERTICES];
    for (int i = 0; i < n; ++i) for (int j = 0; j < n; ++j) distance[i][j] = i == j ? 0 : INF;
    for (int edge = 0; edge < edge_count; ++edge) {
        int64_t source_value = input[2 + 3 * edge], destination_value = input[3 + 3 * edge], weight = input[4 + 3 * edge];
        if (source_value < 0 || source_value >= n || destination_value < 0 || destination_value >= n ||
            source_value == destination_value || weight < 1 || weight > 1000000) return -1;
        int source = (int)source_value, destination = (int)destination_value;
        if (distance[source][destination] != INF) return -1;
        distance[source][destination] = weight;
    }
    for (int middle = 0; middle < n; ++middle)
        for (int source = 0; source < n; ++source) {
            if (distance[source][middle] == INF) continue;
            for (int destination = 0; destination < n; ++destination)
                if (distance[middle][destination] != INF && distance[source][middle] + distance[middle][destination] < distance[source][destination])
                    distance[source][destination] = distance[source][middle] + distance[middle][destination];
        }

    if (n > 1)
        for (int source = 0; source < n; ++source)
            for (int destination = 0; destination < n; ++destination)
                if (source != destination && distance[source][destination] == INF) return -1;

    int peripheral = -1, far = -1, peripheral_infinite = 0, far_infinite = 0, any_reachable = 0;
    int64_t best_eccentricity = -1, best_farness = -1;
    if (n == 1) { peripheral = 0; far = 0; best_eccentricity = 0; best_farness = 0; }
    else {
        for (int source = 0; source < n; ++source) {
            int found = 0;
            int64_t eccentricity = 0, farness = 0;
            for (int destination = 0; destination < n; ++destination) {
                int64_t value = distance[source][destination];
                if (destination == source || value == INF || value == 0) continue;
                found = 1; if (value > eccentricity) eccentricity = value; farness += value;
            }
            if (found) any_reachable = 1;
            int infinite = !found;
            if (peripheral < 0 || (infinite && !peripheral_infinite) ||
                (infinite == peripheral_infinite && (infinite || eccentricity > best_eccentricity ||
                 (eccentricity == best_eccentricity && source < peripheral)))) {
                peripheral = source; peripheral_infinite = infinite; best_eccentricity = eccentricity;
            }
            if (far < 0 || (infinite && !far_infinite) ||
                (infinite == far_infinite && (infinite || farness > best_farness ||
                 (farness == best_farness && source < far)))) {
                far = source; far_infinite = infinite; best_farness = farness;
            }
        }
        if (!any_reachable) { peripheral = -1; far = -1; best_eccentricity = -1; best_farness = -1; }
        else { if (peripheral_infinite) best_eccentricity = -1; if (far_infinite) best_farness = -1; }
    }
    if (!output || capacity < 32) return -2;
    put_i64(output, 0, peripheral); put_i64(output, 1, best_eccentricity);
    put_i64(output, 2, far); put_i64(output, 3, best_farness);
    return 32;
}
