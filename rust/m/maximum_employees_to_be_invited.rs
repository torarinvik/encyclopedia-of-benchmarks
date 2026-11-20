const MAX_N: i64 = 8;
const MAX_INPUT: usize = 10;

#[no_mangle]
pub unsafe extern "C" fn maximum_employees_to_be_invited(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n_value = values[0];
    if !(2..=MAX_N).contains(&n_value) || length != (n_value + 1) as usize { return -1; }
    let n = n_value as usize;
    let mut favorite = [0usize; 8];
    let mut indegree = [0i64; 8];
    let mut chain = [1i64; 8];
    let mut queue = [0usize; 8];
    let mut visited = [false; 8];
    for i in 0..n {
        let target = values[i + 1];
        if target < 0 || target >= n_value || target == i as i64 { return -1; }
        favorite[i] = target as usize;
        indegree[target as usize] += 1;
    }
    let (mut head, mut tail) = (0usize, 0usize);
    for i in 0..n {
        if indegree[i] == 0 { queue[tail] = i; tail += 1; }
    }
    while head < tail {
        let node = queue[head]; head += 1;
        let target = favorite[node];
        chain[target] = chain[target].max(chain[node] + 1);
        indegree[target] -= 1;
        if indegree[target] == 0 { queue[tail] = target; tail += 1; }
    }
    let (mut pair_total, mut longest_cycle) = (0i64, 0i64);
    for start in 0..n {
        if indegree[start] == 0 || visited[start] { continue; }
        let (mut node, mut first, mut second) = (start, 0usize, 0usize);
        let mut cycle_length = 0i64;
        while !visited[node] {
            visited[node] = true;
            if cycle_length == 0 { first = node; }
            else if cycle_length == 1 { second = node; }
            cycle_length += 1;
            node = favorite[node];
        }
        if cycle_length == 2 { pair_total += chain[first] + chain[second]; }
        else { longest_cycle = longest_cycle.max(cycle_length); }
    }
    pair_total.max(longest_cycle)
}
