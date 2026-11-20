// Clean-room bounded Tunstall full-tree construction.
module tunstall_codebook_construction;

const long MAX_S = 4222124650659840;
const long RESULT_FACTOR = MAX_S + 1;

fn long tunstall_codebook_construction(long* input, usz length) @export("tunstall_codebook_construction") {
    if (input == null || length < 4 || length > 7) return -1;
    if (input[0] < 2 || input[0] > 4 || input[1] < 2 || input[1] > 4) return -1;
    int k = (int)input[0];
    int bits = (int)input[1];
    if (length != (usz)k + 2) return -1;

    long[4] weights = {};
    long total = 0;
    for (int i = 0; i < k; i++) {
        long weight = input[2 + i];
        if (weight <= 0 || weight > 8) return -1;
        weights[i] = weight;
        total += weight;
    }
    if (total > 8) return -1;

    long[17] powers = {};
    powers[0] = 1;
    for (int i = 1; i <= 16; i++) powers[i] = powers[i - 1] * total;
    int cap = 1 << bits;
    int target = cap;
    while ((target - 1) % (k - 1) != 0) target--;

    long[31] products = {};
    int[31] depths = {};
    u64[31] phrase_keys = {};
    int[16] leaves = {};
    int node_count = 1;
    int leaf_count = 0;
    for (int symbol = 0; symbol < k; symbol++) {
        int node = node_count++;
        products[node] = weights[symbol];
        depths[node] = 1;
        phrase_keys[node] = (u64)(symbol + 1) << 56;
        leaves[leaf_count++] = node;
    }

    long scaled_expectation = powers[16];
    while (leaf_count < target) {
        int best_position = 0;
        int best_node = leaves[0];
        long best_probability = products[best_node] * powers[15 - depths[best_node]];
        for (int position = 1; position < leaf_count; position++) {
            int candidate = leaves[position];
            long probability = products[candidate] * powers[15 - depths[candidate]];
            if (probability > best_probability ||
                (probability == best_probability && phrase_keys[candidate] < phrase_keys[best_node])) {
                best_position = position;
                best_node = candidate;
                best_probability = probability;
            }
        }

        scaled_expectation += products[best_node] * powers[16 - depths[best_node]];
        leaf_count--;
        leaves[best_position] = leaves[leaf_count];
        for (int symbol = 0; symbol < k; symbol++) {
            int child = node_count++;
            products[child] = products[best_node] * weights[symbol];
            depths[child] = depths[best_node] + 1;
            int shift = 4 * (14 - depths[best_node]);
            phrase_keys[child] = phrase_keys[best_node] | ((u64)(symbol + 1) << shift);
            leaves[leaf_count++] = child;
        }
    }
    long result = (long)target * RESULT_FACTOR + scaled_expectation;
    if (scaled_expectation > MAX_S) return -1;
    return result;
}
