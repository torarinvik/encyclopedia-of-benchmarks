const MAX_N: i64 = 64;
const ENCODING_BASE: i64 = 65;

fn next_node(input: &[i64], node: i64) -> i64 {
    input[2 + node as usize]
}

#[no_mangle]
pub unsafe extern "C" fn functional_graph_cycle_parameters(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > (MAX_N + 2) as usize { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n = values[0];
    let start = values[1];
    if n < 1 || n > MAX_N || start < 0 || start >= n || length != (n + 2) as usize { return -1; }
    if values[2..].iter().any(|&next| next < 0 || next >= n) { return -1; }

    let mut tortoise = next_node(values, start);
    let mut hare = next_node(values, next_node(values, start));
    while tortoise != hare {
        tortoise = next_node(values, tortoise);
        hare = next_node(values, next_node(values, hare));
    }
    let mut mu = 0i64;
    tortoise = start;
    while tortoise != hare {
        tortoise = next_node(values, tortoise);
        hare = next_node(values, hare);
        mu += 1;
    }
    let mut lambda = 1i64;
    hare = next_node(values, tortoise);
    while hare != tortoise {
        hare = next_node(values, hare);
        lambda += 1;
    }
    ENCODING_BASE * mu + lambda
}
