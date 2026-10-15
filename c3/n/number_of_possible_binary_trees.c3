module number_of_possible_binary_trees;

fn long number_of_possible_binary_trees(long node_count) @export("number_of_possible_binary_trees") {
    if (node_count < 1 || node_count > 14) return -1;
    long binomial = 1;
    for (long index = 0; index < node_count; index++) {
        binomial *= 2 * node_count - index;
        binomial /= index + 1;
    }
    long catalan = binomial / (node_count + 1);
    long factorial = 1;
    for (long factor = 2; factor <= node_count; factor++) factorial *= factor;
    return catalan * factorial;
}
