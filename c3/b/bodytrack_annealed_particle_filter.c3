module bodytrack_annealed_particle_filter;

const long MAX_D = 4;
const long MAX_N = 16;
const long MAX_L = 4;
const long MAX_INPUT = 318;
const long Q24 = 16777216;

fn long round_away(long numerator, long denominator) {
    long magnitude = numerator < 0 ? -numerator : numerator;
    long quotient = magnitude / denominator;
    long remainder = magnitude % denominator;
    if (2 * remainder >= denominator) quotient += 1;
    return numerator < 0 ? -quotient : quotient;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits >> (8 * byte));
    }
}

fn long bodytrack_annealed_particle_filter(long* input, usz length,
        char* output, usz capacity) @export("bodytrack_annealed_particle_filter") {
    if (input == null || length < 3 || length > (usz)MAX_INPUT) return -1;
    long d_value = input[0], n_value = input[1], layers_value = input[2];
    if (d_value < 1 || d_value > MAX_D || n_value < 2 || n_value > MAX_N ||
            layers_value < 1 || layers_value > MAX_L) return -1;
    usz d = (usz)d_value, n = (usz)n_value, layers = (usz)layers_value;
    usz expected = 2 + d + 2 * layers + n * d + (layers - 1) * n * (d + 1);
    if (length != expected) return -1;

    usz target_at = 3;
    usz beta_at = target_at + d;
    usz sigma_at = beta_at + layers;
    usz pose_at = sigma_at + layers - 1;
    usz uniform_at = pose_at + n * d;
    usz shock_at = uniform_at + (layers - 1) * n;
    long target[MAX_D], beta[MAX_L], sigma[MAX_L - 1];
    for (usz axis = 0; axis < d; axis += 1) {
        target[axis] = input[target_at + axis];
        if (target[axis] < -10000 || target[axis] > 10000) return -1;
    }
    for (usz layer = 0; layer < layers; layer += 1) {
        beta[layer] = input[beta_at + layer];
        if (beta[layer] < 1 || beta[layer] > 8 ||
                (layer > 0 && beta[layer] <= beta[layer - 1])) return -1;
    }
    for (usz layer = 0; layer + 1 < layers; layer += 1) {
        sigma[layer] = input[sigma_at + layer];
        if (sigma[layer] < 0 || sigma[layer] > 2000 ||
                (layer > 0 && sigma[layer] > sigma[layer - 1])) return -1;
    }
    for (usz i = 0; i < n * d; i += 1)
        if (input[pose_at + i] < -10000 || input[pose_at + i] > 10000) return -1;
    for (usz i = 0; i < (layers - 1) * n; i += 1)
        if (input[uniform_at + i] < 0 || input[uniform_at + i] >= Q24) return -1;
    for (usz i = 0; i < (layers - 1) * n * d; i += 1)
        if (input[shock_at + i] < -3000 || input[shock_at + i] > 3000) return -1;

    usz required = 8 * d;
    if (output == null || capacity < required) return -2;
    long population[2][MAX_N][MAX_D], weights[MAX_N], estimate[MAX_D];
    for (usz particle = 0; particle < n; particle += 1)
        for (usz axis = 0; axis < d; axis += 1)
            population[0][particle][axis] = input[pose_at + particle * d + axis];

    usz active = 0;
    for (usz layer = 0; layer < layers; layer += 1) {
        long total_weight = 0;
        for (usz particle = 0; particle < n; particle += 1) {
            long squared_distance = 0;
            for (usz axis = 0; axis < d; axis += 1) {
                long delta = population[active][particle][axis] - target[axis];
                squared_distance += delta * delta;
            }
            long energy = squared_distance / 10000;
            long base = (Q24 * 100000) / (100000 + energy);
            long weight = base;
            for (long power = 1; power < beta[layer]; power += 1)
                weight = (weight * base) / Q24;
            weights[particle] = weight;
            total_weight += weight;
        }
        if (layer + 1 == layers) {
            for (usz axis = 0; axis < d; axis += 1) {
                long moment = 0;
                for (usz particle = 0; particle < n; particle += 1)
                    moment += weights[particle] * population[active][particle][axis];
                estimate[axis] = round_away(moment, total_weight);
            }
            break;
        }
        usz destination = 1 - active;
        for (usz child = 0; child < n; child += 1) {
            long draw = input[uniform_at + layer * n + child];
            long threshold = (draw * total_weight) / Q24;
            long cumulative = 0;
            usz ancestor = 0;
            while (cumulative <= threshold) {
                cumulative += weights[ancestor];
                ancestor += 1;
            }
            ancestor -= 1;
            for (usz axis = 0; axis < d; axis += 1) {
                usz shock_index = shock_at + layer * n * d + child * d + axis;
                long movement = round_away(sigma[layer] * input[shock_index], 1000);
                long coordinate = population[active][ancestor][axis] + movement;
                if (coordinate < -10000) coordinate = -10000;
                if (coordinate > 10000) coordinate = 10000;
                population[destination][child][axis] = coordinate;
            }
        }
        active = destination;
    }
    for (usz axis = 0; axis < d; axis += 1)
        store_i64_le(output, 8 * axis, estimate[axis]);
    return (long)required;
}
