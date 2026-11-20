const MAX_N: usize = 64;
const MAX_PARSEABLE: usize = 66;

fn build_successors(values: &[i64], descending: bool) -> [i64; MAX_N] {
    let n = values.len();
    let mut order = [0usize; MAX_N];
    let mut stack = [0usize; MAX_N];
    let mut target = [-1i64; MAX_N];
    for i in 0..n { order[i] = i; }
    for i in 1..n {
        let key = order[i];
        let mut position = i;
        while position > 0 {
            let previous = order[position - 1];
            let before = if values[key] == values[previous] {
                key < previous
            } else if descending {
                values[key] > values[previous]
            } else {
                values[key] < values[previous]
            };
            if !before { break; }
            order[position] = previous;
            position -= 1;
        }
        order[position] = key;
    }
    let mut stack_size = 0usize;
    for &index in &order[..n] {
        while stack_size > 0 && stack[stack_size - 1] < index {
            stack_size -= 1;
            target[stack[stack_size]] = index as i64;
        }
        stack[stack_size] = index;
        stack_size += 1;
    }
    target
}

#[no_mangle]
pub unsafe extern "C" fn odd_even_jump_reachability_count(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_PARSEABLE { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    if !(1..=MAX_N as i64).contains(&values[0]) { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|&v| !(-1_000_000..=1_000_000).contains(&v)) {
        return -1;
    }
    let data = &values[1..];
    let odd_next = build_successors(data, false);
    let even_next = build_successors(data, true);
    let mut odd = [false; MAX_N];
    let mut even = [false; MAX_N];
    odd[n - 1] = true;
    even[n - 1] = true;
    for index in (0..n - 1).rev() {
        if odd_next[index] >= 0 { odd[index] = even[odd_next[index] as usize]; }
        if even_next[index] >= 0 { even[index] = odd[even_next[index] as usize]; }
    }
    odd[..n].iter().filter(|&&reachable| reachable).count() as i64
}
