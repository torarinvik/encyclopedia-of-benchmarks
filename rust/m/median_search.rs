const MAX_VALUES: usize = 25;
const MAX_INPUT_LENGTH: usize = 28;

fn insertion_sort(values: &mut [i64]) {
    for index in 1..values.len() {
        let value = values[index];
        let mut position = index;
        while position > 0 && values[position - 1] > value {
            values[position] = values[position - 1];
            position -= 1;
        }
        values[position] = value;
    }
}

fn select_kth(values: &mut [i64], rank: usize) -> i64 {
    let mut medians = [0_i64; 5];
    let mut median_count = 0;
    let mut start = 0;
    while start < values.len() {
        let end = (start + 5).min(values.len());
        insertion_sort(&mut values[start..end]);
        medians[median_count] = values[(start + end) / 2];
        median_count += 1;
        start += 5;
    }
    insertion_sort(&mut medians[..median_count]);
    let pivot = medians[(median_count - 1) / 2];

    let mut lower = [0_i64; MAX_VALUES];
    let mut higher = [0_i64; MAX_VALUES];
    let (mut lower_count, mut higher_count) = (0, 0);
    for &value in values.iter() {
        if value < pivot {
            lower[lower_count] = value;
            lower_count += 1;
        } else if value > pivot {
            higher[higher_count] = value;
            higher_count += 1;
        }
    }
    if rank < lower_count {
        return select_kth(&mut lower[..lower_count], rank);
    }
    if rank > lower_count {
        return select_kth(&mut higher[..higher_count], rank - lower_count - 1);
    }
    pivot
}

#[no_mangle]
pub unsafe extern "C" fn median_search(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH {
        return -1;
    }
    let input = std::slice::from_raw_parts(input, length);
    let (count_value, rank_value) = (input[0], input[1]);
    if !(1..=MAX_VALUES as i64).contains(&count_value)
        || rank_value < 0
        || rank_value >= count_value
        || length != count_value as usize + 2
    {
        return -1;
    }

    let count = count_value as usize;
    let mut values = [0_i64; MAX_VALUES];
    for index in 0..count {
        let value = input[index + 2];
        if !(0..=2_147_483_647).contains(&value) || values[..index].contains(&value) {
            return -1;
        }
        values[index] = value;
    }
    select_kth(&mut values[..count], rank_value as usize)
}
