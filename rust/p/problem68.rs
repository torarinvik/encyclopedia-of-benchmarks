fn value_at(values: &[i64; 10], indices: &[i64; 10], position: usize) -> i64 {
    values[indices[position] as usize]
}

fn next_permutation(indices: &mut [i64], length: usize) -> bool {
    let mut pivot = length as isize - 2;
    while pivot >= 0 && indices[pivot as usize] >= indices[pivot as usize + 1] { pivot -= 1; }
    if pivot < 0 { return false; }
    let pivot = pivot as usize;
    let mut successor = length - 1;
    while indices[successor] <= indices[pivot] { successor -= 1; }
    indices.swap(pivot, successor);
    indices[pivot + 1..length].reverse();
    true
}

#[no_mangle]
pub extern "C" fn problem68(gon_side: i64) -> i64 {
    if !(3..=5).contains(&gon_side) { return -1; }
    let n = gon_side as usize;
    let length = 2 * n;
    let mut values = [0_i64; 10];
    let mut cursor = 0;
    for value in (1..=n + 1).rev() { values[cursor] = value as i64; cursor += 1; }
    for value in n + 2..=2 * n { values[cursor] = value as i64; cursor += 1; }
    let mut indices = [0_i64; 10];
    for i in 0..length { indices[i] = i as i64; }
    loop {
        let total = value_at(&values, &indices, 0) + value_at(&values, &indices, 1) + value_at(&values, &indices, 2);
        let mut magic = true;
        let mut minimum_outer = value_at(&values, &indices, 0);
        for line in 1..n {
            let outer = if line == n - 1 { 2 * n - 1 } else { 2 * line + 1 };
            let inner_left = 2 * line;
            let inner_right = if line == n - 1 { 1 } else { 2 * line + 2 };
            if value_at(&values, &indices, outer) + value_at(&values, &indices, inner_left) + value_at(&values, &indices, inner_right) != total { magic = false; }
            minimum_outer = minimum_outer.min(value_at(&values, &indices, outer));
        }
        if magic && value_at(&values, &indices, 0) == minimum_outer {
            let mut result = 0_i64;
            for line in 0..n {
                let outer = if line == 0 { 0 } else if line == n - 1 { 2 * n - 1 } else { 2 * line + 1 };
                let inner_left = if line == 0 { 1 } else { 2 * line };
                let inner_right = if line == n - 1 { 1 } else if line == 0 { 2 } else { 2 * line + 2 };
                for value in [value_at(&values, &indices, outer), value_at(&values, &indices, inner_left), value_at(&values, &indices, inner_right)] {
                    result = result * (if value >= 10 { 100 } else { 10 }) + value;
                }
            }
            return result;
        }
        if !next_permutation(&mut indices, length) { break; }
    }
    -1
}
