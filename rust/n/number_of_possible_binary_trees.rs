/// Count labeled binary trees using the pinned Catalan-times-factorial formula.
#[no_mangle]
pub extern "C" fn number_of_possible_binary_trees(node_count: i64) -> i64 {
    if !(1..=14).contains(&node_count) { return -1; }
    let mut binomial = 1i64;
    for index in 0..node_count {
        binomial *= 2 * node_count - index;
        binomial /= index + 1;
    }
    let catalan = binomial / (node_count + 1);
    let mut factorial = 1i64;
    for factor in 2..=node_count { factorial *= factor; }
    catalan * factorial
}
