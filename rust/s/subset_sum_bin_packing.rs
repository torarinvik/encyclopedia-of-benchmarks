const MAX_ITEMS: usize = 16;
const MAX_CAPACITY: usize = 32;
const MAX_INPUT_LENGTH: usize = 19;

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.len() < 2 || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let raw_count = input[0];
    let raw_capacity = input[1];
    if raw_count < 1 || raw_count > MAX_ITEMS as i64 ||
        raw_capacity < 1 || raw_capacity > MAX_CAPACITY as i64 { return Err(()); }
    let count = raw_count as usize;
    let capacity = raw_capacity as usize;
    if input.len() != count + 2 { return Err(()); }

    let mut remaining_size = [0i64; MAX_ITEMS];
    let mut remaining_item = [0usize; MAX_ITEMS];
    let mut assigned_bin = [0i64; MAX_ITEMS];
    for index in 0..count {
        let size = input[index + 2];
        if size < 1 || size > raw_capacity { return Err(()); }
        remaining_size[index] = size;
        remaining_item[index] = index;
    }

    let mut remaining_count = count;
    let mut bin_count = 0i64;
    while remaining_count > 0 {
        let mut reachable = [[false; MAX_CAPACITY + 1]; MAX_ITEMS + 1];
        reachable[remaining_count][0] = true;
        for row in (0..remaining_count).rev() {
            let size = remaining_size[row] as usize;
            for sum in 0..=capacity {
                reachable[row][sum] = reachable[row + 1][sum];
                if sum >= size && reachable[row + 1][sum - size] {
                    reachable[row][sum] = true;
                }
            }
        }

        let mut target = capacity;
        while target > 0 && !reachable[0][target] { target -= 1; }
        let mut selected = [false; MAX_ITEMS];
        let mut needed = target;
        for item in 0..remaining_count {
            let size = remaining_size[item] as usize;
            if size <= needed && reachable[item + 1][needed - size] {
                selected[item] = true;
                needed -= size;
                assigned_bin[remaining_item[item]] = bin_count;
            }
        }

        let mut survivors = 0;
        for item in 0..remaining_count {
            if !selected[item] {
                remaining_size[survivors] = remaining_size[item];
                remaining_item[survivors] = remaining_item[item];
                survivors += 1;
            }
        }
        remaining_count = survivors;
        bin_count += 1;
    }

    let mut checksum = bin_count * 10000;
    for index in 0..count {
        checksum += (index as i64 + 1) * (assigned_bin[index] + 1);
    }
    Ok(checksum)
}

#[no_mangle]
pub unsafe extern "C" fn subset_sum_bin_packing(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
