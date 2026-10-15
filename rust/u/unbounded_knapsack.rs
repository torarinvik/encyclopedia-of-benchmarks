const MAX_ITEMS: usize = 16;
const MAX_CAPACITY: usize = 100;

fn solve(item: usize, capacity: usize, values: &[i64], weights: &[i64], memo: &mut [[i64; MAX_CAPACITY + 1]; MAX_ITEMS]) -> i64 {
    if item == 0 { return (capacity as i64 / weights[0]) * values[0]; }
    if memo[item][capacity] >= 0 { return memo[item][capacity]; }
    let skip = solve(item - 1, capacity, values, weights, memo);
    let take = if capacity as i64 >= weights[item] { values[item] + solve(item, capacity - weights[item] as usize, values, weights, memo) } else { 0 };
    memo[item][capacity] = take.max(skip);
    memo[item][capacity]
}

/// Solve the unbounded knapsack recurrence for positive item values and weights.
#[no_mangle]
pub unsafe extern "C" fn unbounded_knapsack(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_ITEMS as i64).contains(&input[0]) || !(0..=MAX_CAPACITY as i64).contains(&input[1]) { return -1; }
    let n=input[0] as usize; let capacity=input[1] as usize;
    if length != 2 + 2*n { return -1; }
    if n==0 { return 0; }
    let values=&input[2..2+n]; let weights=&input[2+n..2+2*n];
    if values.iter().any(|&x| !(1..=100).contains(&x)) || weights.iter().any(|&x| !(1..=100).contains(&x)) { return -1; }
    let mut memo=[[-1i64;MAX_CAPACITY+1];MAX_ITEMS];
    solve(n-1,capacity,values,weights,&mut memo)
}
