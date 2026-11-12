// Clean-room bounded implementation of the Library Checker sequence-counting task.
const MAX_N: usize = 64;
const MAX_M: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MOD: i64 = 998_244_353;

#[no_mangle]
pub unsafe extern "C" fn number_of_increasing_sequences_between_two_sequences(
    input: *const i64, length: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_N as i64 || values[1] < 1 || values[1] > MAX_M as i64 { return -1; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + 2 * n { return -1; }
    let mut lower = [0i64; MAX_N];
    let mut upper = [0i64; MAX_N];
    for i in 0..n {
        lower[i] = values[2 + i];
        upper[i] = values[2 + n + i];
        if lower[i] < 0 || lower[i] >= upper[i] || upper[i] > m as i64 { return -1; }
    }
    let mut previous = [0i64; MAX_M];
    let mut current = [0i64; MAX_M];
    for value in lower[0] as usize..upper[0] as usize { previous[value] = 1; }
    for position in 1..n {
        let mut prefix = 0i64;
        for value in 0..m {
            prefix += previous[value];
            if prefix >= MOD { prefix -= MOD; }
            current[value] = if lower[position] <= value as i64 && (value as i64) < upper[position] { prefix } else { 0 };
        }
        std::mem::swap(&mut previous, &mut current);
    }
    let mut answer = 0i64;
    for value in 0..m {
        answer += previous[value];
        if answer >= MOD { answer -= MOD; }
    }
    answer
}
