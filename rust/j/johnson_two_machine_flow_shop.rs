const MAX_JOBS: usize = 8;
const MAX_TIME: i64 = 1000;

fn solve(input: &[i64]) -> i64 {
    if input.is_empty() || !(1..=MAX_JOBS as i64).contains(&input[0]) { return -1; }
    let count = input[0] as usize;
    if input.len() != 1 + 2 * count { return -1; }
    let mut first = [0i64; MAX_JOBS];
    let mut second = [0i64; MAX_JOBS];
    let mut early = [0usize; MAX_JOBS];
    let mut late = [0usize; MAX_JOBS];
    let mut early_count = 0usize;
    let mut late_count = 0usize;
    for job in 0..count {
        first[job] = input[1 + 2 * job];
        second[job] = input[2 + 2 * job];
        if !(0..=MAX_TIME).contains(&first[job]) || !(0..=MAX_TIME).contains(&second[job]) { return -1; }
        let is_early = first[job] < second[job];
        let mut position = if is_early { early_count } else { late_count };
        while position > 0 {
            let previous = if is_early { early[position - 1] } else { late[position - 1] };
            let comes_before = if is_early {
                first[job] < first[previous] || (first[job] == first[previous] && job < previous)
            } else {
                second[job] > second[previous] || (second[job] == second[previous] && job < previous)
            };
            if !comes_before { break; }
            if is_early { early[position] = previous; } else { late[position] = previous; }
            position -= 1;
        }
        if is_early { early[position] = job; early_count += 1; }
        else { late[position] = job; late_count += 1; }
    }
    let mut first_finish = 0i64;
    let mut second_finish = 0i64;
    for index in 0..count {
        let job = if index < early_count { early[index] } else { late[index - early_count] };
        first_finish += first[job];
        second_finish = second_finish.max(first_finish) + second[job];
    }
    second_finish
}

#[no_mangle]
pub unsafe extern "C" fn johnson_two_machine_flow_shop(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > 17 { return -1; }
    solve(std::slice::from_raw_parts(input, length))
}
