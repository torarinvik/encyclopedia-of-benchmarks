module stochastic_knapsack_greedy;

const usz MAX_ITEMS = 5;
const usz MAX_ATOMS = 3;
const usz MAX_INPUT = 43;
const usz MAX_OUTPUT_WORDS = 9;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long stochastic_knapsack_greedy(long* input, usz length, char* output, usz capacity) @export("stochastic_knapsack_greedy") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_raw = input[0], bound_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_ITEMS || bound_raw < 1 || bound_raw > 8) return -1;
    int n = (int)n_raw, bound = (int)bound_raw;
    long[MAX_ITEMS] rewards = zeroed, denominators = zeroed, fits = zeroed, means = zeroed;
    int[MAX_ITEMS] atom_counts = zeroed;
    long[MAX_ITEMS][MAX_ATOMS] sizes = zeroed, weights = zeroed;
    usz position = 2;
    for (int item = 0; item < n; item += 1) {
        if (position + 2 > length) return -1;
        long reward = input[position], atom_count_raw = input[position + 1];
        position += 2;
        if (reward < 0 || reward > 20 || atom_count_raw < 1 || atom_count_raw > (long)MAX_ATOMS) return -1;
        rewards[item] = reward;
        atom_counts[item] = (int)atom_count_raw;
        for (int atom = 0; atom < atom_counts[item]; atom += 1) {
            if (position + 2 > length) return -1;
            long size = input[position], weight = input[position + 1];
            position += 2;
            if (size < 0 || size > bound + 1 || weight < 1 || weight > 3) return -1;
            sizes[item][atom] = size; weights[item][atom] = weight;
            denominators[item] += weight;
            if (size <= bound) fits[item] += weight;
            long capped = size < bound ? size : bound;
            means[item] += capped * weight;
        }
        if (denominators[item] > 9 || means[item] == 0) return -1;
    }
    if (position != length) return -1;

    int[MAX_ITEMS] order = zeroed;
    for (int i = 0; i < n; i += 1) {
        int j = i;
        while (j > 0) {
            int previous = order[j - 1];
            long left_score = rewards[i] * fits[i] * means[previous];
            long right_score = rewards[previous] * fits[previous] * means[i];
            if (left_score < right_score || (left_score == right_score && i > previous)) break;
            order[j] = previous; j -= 1;
        }
        order[j] = i;
    }
    int best_single = 0;
    for (int i = 1; i < n; i += 1) {
        long left_score = rewards[i] * fits[i] * denominators[best_single];
        long right_score = rewards[best_single] * fits[best_single] * denominators[i];
        if (left_score > right_score) best_single = i;
    }
    long joint_denominator = 1;
    int scenario_count = 1;
    for (int i = 0; i < n; i += 1) {
        joint_denominator *= denominators[i];
        scenario_count *= atom_counts[i];
    }
    long singleton_score = 0, order_score = 0;
    for (int scenario = 0; scenario < scenario_count; scenario += 1) {
        int digits = scenario;
        long scenario_weight = 1;
        long[MAX_ITEMS] selected_size = zeroed;
        for (int item = 0; item < n; item += 1) {
            int atom = digits % atom_counts[item]; digits /= atom_counts[item];
            selected_size[item] = sizes[item][atom];
            scenario_weight *= weights[item][atom];
        }
        if (selected_size[best_single] <= bound) singleton_score += scenario_weight * rewards[best_single];
        int used = 0;
        long earned = 0;
        for (int rank = 0; rank < n; rank += 1) {
            int selected = order[rank];
            if (used + selected_size[selected] > bound) break;
            used += (int)selected_size[selected];
            earned += rewards[selected];
        }
        order_score += scenario_weight * earned;
    }

    bool use_order = order_score > singleton_score;
    int output_count = use_order ? n : 1;
    long[MAX_OUTPUT_WORDS] staged = zeroed;
    staged[0] = use_order ? 1 : 0;
    staged[1] = output_count;
    for (int i = 0; i < output_count; i += 1) staged[2 + i] = use_order ? order[i] : best_single;
    staged[2 + output_count] = use_order ? order_score : singleton_score;
    staged[3 + output_count] = joint_denominator;
    usz words = (usz)(output_count + 4), bytes = words * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz word = 0; word < words; word += 1) store_i64_le(output, word * 8, staged[word]);
    return (long)bytes;
}
