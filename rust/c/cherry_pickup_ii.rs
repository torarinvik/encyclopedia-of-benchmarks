const MAX_DIM: usize = 6;
const MAX_INPUT: usize = 39;

#[no_mangle]
pub unsafe extern "C" fn cherry_pickup_ii(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (rows_value, columns_value) = (values[0], values[1]);
    if !(2..=MAX_DIM as i64).contains(&rows_value) || !(2..=MAX_DIM as i64).contains(&columns_value) { return -1; }
    let (rows, columns) = (rows_value as usize, columns_value as usize);
    if length != 2 + rows * columns || values[2..].iter().any(|&value| !(0..=100).contains(&value)) { return -1; }
    let mut previous = [-1i64; MAX_DIM * MAX_DIM];
    let mut current = [-1i64; MAX_DIM * MAX_DIM];
    previous[columns - 1] = values[2] + values[2 + columns - 1];
    for row in 1..rows {
        current.fill(-1);
        for left in 0..columns {
            for right in 0..columns {
                let score = previous[left * columns + right];
                if score < 0 { continue; }
                for dl in -1isize..=1 {
                    let next_left = left as isize + dl;
                    if next_left < 0 || next_left >= columns as isize { continue; }
                    for dr in -1isize..=1 {
                        let next_right = right as isize + dr;
                        if next_right < 0 || next_right >= columns as isize { continue; }
                        let (next_left, next_right) = (next_left as usize, next_right as usize);
                        let mut candidate = score + values[2 + row * columns + next_left];
                        if next_left != next_right { candidate += values[2 + row * columns + next_right]; }
                        let slot = next_left * columns + next_right;
                        current[slot] = current[slot].max(candidate);
                    }
                }
            }
        }
        previous = current;
    }
    let mut answer = -1;
    for left in 0..columns {
        for right in 0..columns { answer = answer.max(previous[left * columns + right]); }
    }
    answer
}
