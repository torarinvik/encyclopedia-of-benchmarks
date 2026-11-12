#include <stddef.h>
#include <stdint.h>

#define MAX_D 4
#define MAX_N 16
#define MAX_L 4
#define MAX_INPUT 318
#define Q24 INT64_C(16777216)

static int64_t round_away(int64_t numerator, int64_t denominator) {
    int64_t magnitude = numerator < 0 ? -numerator : numerator;
    int64_t quotient = magnitude / denominator;
    int64_t remainder = magnitude % denominator;
    if (2 * remainder >= denominator) ++quotient;
    return numerator < 0 ? -quotient : quotient;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bodytrack_annealed_particle_filter(const int64_t *input, size_t length,
                                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t d_value = input[0], n_value = input[1], layers_value = input[2];
    if (d_value < 1 || d_value > MAX_D || n_value < 2 || n_value > MAX_N ||
        layers_value < 1 || layers_value > MAX_L) return -1;
    size_t d = (size_t)d_value, n = (size_t)n_value, layers = (size_t)layers_value;
    size_t expected = 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1);
    if (length != expected) return -1;

    size_t target_at = 3;
    size_t beta_at = target_at + d;
    size_t sigma_at = beta_at + layers;
    size_t pose_at = sigma_at + layers - 1;
    size_t uniform_at = pose_at + n * d;
    size_t shock_at = uniform_at + (layers - 1) * n;
    int64_t target[MAX_D], beta[MAX_L], sigma[MAX_L - 1];
    for (size_t axis = 0; axis < d; ++axis) {
        target[axis] = input[target_at + axis];
        if (target[axis] < -10000 || target[axis] > 10000) return -1;
    }
    for (size_t layer = 0; layer < layers; ++layer) {
        beta[layer] = input[beta_at + layer];
        if (beta[layer] < 1 || beta[layer] > 8 ||
            (layer > 0 && beta[layer] <= beta[layer - 1])) return -1;
    }
    for (size_t layer = 0; layer + 1 < layers; ++layer) {
        sigma[layer] = input[sigma_at + layer];
        if (sigma[layer] < 0 || sigma[layer] > 2000 ||
            (layer > 0 && sigma[layer] > sigma[layer - 1])) return -1;
    }
    for (size_t item = 0; item < n * d; ++item)
        if (input[pose_at + item] < -10000 || input[pose_at + item] > 10000) return -1;
    for (size_t item = 0; item < (layers - 1) * n; ++item)
        if (input[uniform_at + item] < 0 || input[uniform_at + item] >= Q24) return -1;
    for (size_t item = 0; item < (layers - 1) * n * d; ++item)
        if (input[shock_at + item] < -3000 || input[shock_at + item] > 3000) return -1;

    size_t required = 8 * d;
    if (output == NULL || capacity < required) return -2;

    int64_t storage_a[MAX_N][MAX_D], storage_b[MAX_N][MAX_D];
    int64_t (*population)[MAX_D] = storage_a;
    int64_t (*next_population)[MAX_D] = storage_b;
    int64_t weights[MAX_N];
    for (size_t particle = 0; particle < n; ++particle)
        for (size_t axis = 0; axis < d; ++axis)
            population[particle][axis] = input[pose_at + particle * d + axis];

    int64_t estimate[MAX_D];
    for (size_t layer = 0; layer < layers; ++layer) {
        int64_t total_weight = 0;
        for (size_t particle = 0; particle < n; ++particle) {
            int64_t squared_distance = 0;
            for (size_t axis = 0; axis < d; ++axis) {
                int64_t delta = population[particle][axis] - target[axis];
                squared_distance += delta * delta;
            }
            int64_t energy = squared_distance / 10000;
            int64_t base = (Q24 * 100000) / (100000 + energy);
            int64_t weight = base;
            for (int64_t power = 1; power < beta[layer]; ++power)
                weight = (weight * base) / Q24;
            weights[particle] = weight;
            total_weight += weight;
        }

        if (layer + 1 == layers) {
            for (size_t axis = 0; axis < d; ++axis) {
                int64_t moment = 0;
                for (size_t particle = 0; particle < n; ++particle)
                    moment += weights[particle] * population[particle][axis];
                estimate[axis] = round_away(moment, total_weight);
            }
            break;
        }

        for (size_t child = 0; child < n; ++child) {
            int64_t draw = input[uniform_at + layer * n + child];
            int64_t threshold = (draw * total_weight) / Q24;
            int64_t cumulative = 0;
            size_t ancestor = 0;
            while (cumulative <= threshold) cumulative += weights[ancestor++];
            --ancestor;
            for (size_t axis = 0; axis < d; ++axis) {
                size_t shock_index = shock_at + layer * n * d + child * d + axis;
                int64_t movement = round_away(sigma[layer] * input[shock_index], 1000);
                int64_t coordinate = population[ancestor][axis] + movement;
                if (coordinate < -10000) coordinate = -10000;
                if (coordinate > 10000) coordinate = 10000;
                next_population[child][axis] = coordinate;
            }
        }
        int64_t (*temporary)[MAX_D] = population;
        population = next_population;
        next_population = temporary;
    }
    for (size_t axis = 0; axis < d; ++axis)
        store_i64_le(output, 8 * axis, estimate[axis]);
    return (int64_t)required;
}
