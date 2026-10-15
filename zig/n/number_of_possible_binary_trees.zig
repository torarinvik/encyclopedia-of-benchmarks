/// Count labeled binary trees using the pinned Catalan-times-factorial formula.
export fn number_of_possible_binary_trees(node_count: i64) i64 {
    if (node_count < 1 or node_count > 14) return -1;
    var binomial: i64 = 1;
    var index: i64 = 0;
    while (index < node_count) : (index += 1) {
        binomial *= 2 * node_count - index;
        binomial = @divTrunc(binomial, index + 1);
    }
    const catalan = @divTrunc(binomial, node_count + 1);
    var factorial: i64 = 1;
    var factor: i64 = 2;
    while (factor <= node_count) : (factor += 1) factorial *= factor;
    return catalan * factorial;
}
