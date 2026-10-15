/// Count task assignments with one distinct eligible task per person.
#[no_mangle]
pub extern "C" fn assignment_using_bitmask(input: *const i64, length: usize) -> i64 {
    if length < 2 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let people = input[0];
    let tasks = input[1];
    if !(0..=10).contains(&people) || !(0..=10).contains(&tasks)
        || length != 2 + people as usize { return -1; }
    let valid_tasks = (1i64 << tasks) - 1;
    if input[2..].iter().any(|&mask| mask < 0 || mask > valid_tasks) { return -1; }

    let states = 1usize << people as usize;
    let mut ways = [0i64; 4096];
    let mut next = [0i64; 4096];
    ways[0] = 1;
    for task in 0..tasks as usize {
        next[..states].fill(0);
        for mask in 0..states {
            let count = ways[mask];
            if count == 0 { continue; }
            next[mask] += count;
            for person in 0..people as usize {
                let bit = 1usize << person;
                if mask & bit == 0 && input[2 + person] & (1i64 << task) != 0 {
                    next[mask | bit] += count;
                }
            }
        }
        ways = next;
    }
    ways[states - 1]
}
