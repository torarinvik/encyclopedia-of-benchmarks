module k_ary_huffman_weighted_path_cost;

fn long k_ary_huffman_weighted_path_cost(long* input, usz length)
    @export("k_ary_huffman_weighted_path_cost") {
    if (input == null || length < 3 || length > 13) return -1;
    long arity_value = input[0];
    long count_value = input[1];
    if ((arity_value != 3 && arity_value != 4) || count_value < 1 || count_value > 10) return -1;
    usz arity = (usz)arity_value;
    usz count = (usz)count_value;
    if (length != count + 2 || (count > 1 && (count - 1) % (arity - 1) != 0)) return -1;

    long[16] weights;
    bool[16] active;
    for (usz index = 0; index < 16; index++) {
        weights[index] = 0;
        active[index] = false;
    }
    for (usz index = 0; index < count; index++) {
        long weight = input[index + 2];
        if (weight < 0 || weight > 1000) return -1;
        weights[index] = weight;
        active[index] = true;
    }

    usz node_count = count;
    usz active_count = count;
    long cost = 0;
    while (active_count > 1) {
        long combined = 0;
        for (usz pick = 0; pick < arity; pick++) {
            usz best = 16;
            for (usz index = 0; index < node_count; index++) {
                if (!active[index]) continue;
                if (best == 16) best = index;
                else if (weights[index] < weights[best]
                    || (weights[index] == weights[best] && index < best)) best = index;
            }
            if (best == 16) return -1;
            combined += weights[best];
            active[best] = false;
            active_count--;
        }
        cost += combined;
        weights[node_count] = combined;
        active[node_count] = true;
        node_count++;
        active_count++;
    }
    return cost;
}
