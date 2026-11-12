const MAX_N: usize = 512;
const MODULUS: i64 = 998_244_353;

fn mod_pow(mut base: i64, mut exponent: usize) -> i64 {
    let mut result = 1i64;
    while exponent > 0 {
        if exponent & 1 != 0 { result = result * base % MODULUS; }
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    result
}

fn solve(n: usize) -> i64 {
    let mut factorial = [0i64; MAX_N + 1];
    let mut inverse_factorial = [0i64; MAX_N + 1];
    let mut all_graphs = [0i64; MAX_N + 1];
    let mut connected = [0i64; MAX_N + 1];
    factorial[0] = 1;
    for i in 1..=n { factorial[i] = factorial[i - 1] * i as i64 % MODULUS; }
    inverse_factorial[n] = mod_pow(factorial[n], 998_244_351);
    for i in (1..=n).rev() { inverse_factorial[i - 1] = inverse_factorial[i] * i as i64 % MODULUS; }

    all_graphs[0] = 1;
    let mut edge_choices = 1i64;
    for size in 1..=n {
        all_graphs[size] = all_graphs[size - 1] * edge_choices % MODULUS;
        edge_choices = edge_choices * 2 % MODULUS;
    }
    connected[1] = 1;
    for size in 2..=n {
        let mut disconnected = 0i64;
        for component_size in 1..size {
            let mut choose = factorial[size - 1] * inverse_factorial[component_size - 1] % MODULUS;
            choose = choose * inverse_factorial[size - component_size] % MODULUS;
            let mut term = choose * connected[component_size] % MODULUS;
            term = term * all_graphs[size - component_size] % MODULUS;
            disconnected = (disconnected + term) % MODULUS;
        }
        connected[size] = (all_graphs[size] - disconnected + MODULUS) % MODULUS;
    }
    connected[n]
}

#[no_mangle]
pub unsafe extern "C" fn connected_labeled_graph_count(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let value = *input;
    if !(1..=MAX_N as i64).contains(&value) { return -1; }
    solve(value as usize)
}
