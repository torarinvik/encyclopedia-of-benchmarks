const MAX_VERTICES: i64 = 256;
const MAX_PARSEABLE_LENGTH: usize = 258;

#[no_mangle]
pub unsafe extern "C" fn erdos_gallai_graphical_sequence(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length == 0 || length > MAX_PARSEABLE_LENGTH {
        return -1;
    }
    let count_value = *input;
    if !(0..=MAX_VERTICES).contains(&count_value) {
        return -1;
    }
    let count = count_value as usize;
    if length != count + 1 {
        return -1;
    }

    let mut degrees = [0i64; 256];
    let mut degree_sum = 0i64;
    for index in 0..count {
        let degree = *input.add(index + 1);
        if degree < 0 || degree >= count_value {
            return -1;
        }
        degrees[index] = degree;
        degree_sum += degree;
    }
    if count == 0 {
        return 1;
    }
    if degree_sum % 2 != 0 {
        return 0;
    }

    degrees[..count].sort_unstable_by(|left, right| right.cmp(left));
    let mut prefix = [0i64; 257];
    for index in 0..count {
        prefix[index + 1] = prefix[index] + degrees[index];
    }

    for k in 1..=count {
        let mut low = k;
        let mut high = count;
        while low < high {
            let middle = low + (high - low) / 2;
            if degrees[middle] >= k as i64 {
                low = middle + 1;
            } else {
                high = middle;
            }
        }
        let boundary = low;
        let k_value = k as i64;
        let right_side = k_value * (k_value - 1)
            + k_value * (boundary - k) as i64
            + prefix[count]
            - prefix[boundary];
        if prefix[k] > right_side {
            return 0;
        }
    }
    1
}
