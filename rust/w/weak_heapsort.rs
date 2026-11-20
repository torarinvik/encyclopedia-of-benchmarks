const MAX_VALUES: usize = 256;
const MAX_INPUT_LENGTH: usize = 258;

fn reverse_offset(reverse: &[bool; MAX_VALUES], index: usize) -> usize {
    if reverse[index] { 1 } else { 0 }
}

fn distinguished_ancestor(mut node: usize, reverse: &[bool; MAX_VALUES]) -> usize {
    while node > 0 {
        let parent = node / 2;
        if (node % 2 == 0 && !reverse[parent]) || (node % 2 == 1 && reverse[parent]) {
            node = parent;
        } else {
            break;
        }
    }
    node / 2
}

fn join(values: &mut [i64; MAX_VALUES], reverse: &mut [bool; MAX_VALUES], ancestor: usize, node: usize) {
    if values[ancestor] < values[node] {
        values.swap(ancestor, node);
        reverse[node] = !reverse[node];
    }
}

fn sift_down(values: &mut [i64; MAX_VALUES], reverse: &mut [bool; MAX_VALUES], active_size: usize) {
    let mut node = if reverse[0] { 0 } else { 1 };
    if node >= active_size { return; }
    while 2 * node + reverse_offset(reverse, node) < active_size {
        node = 2 * node + reverse_offset(reverse, node);
    }
    while node != 0 {
        join(values, reverse, 0, node);
        node /= 2;
    }
}

fn execute(input: &[i64]) -> Result<i64, ()> {
    if input.is_empty() || input.len() > MAX_INPUT_LENGTH { return Err(()); }
    let count64 = input[0];
    if count64 < 0 || count64 > MAX_VALUES as i64 || input.len() != count64 as usize + 1 { return Err(()); }
    let count = count64 as usize;
    let mut values = [0i64; MAX_VALUES];
    let mut reverse = [false; MAX_VALUES];
    for index in 0..count {
        let value = input[index + 1];
        if !(-1000..=1000).contains(&value) { return Err(()); }
        values[index] = value;
    }

    let mut node = count;
    while node > 1 {
        node -= 1;
        let ancestor = distinguished_ancestor(node, &reverse);
        join(&mut values, &mut reverse, ancestor, node);
    }
    let mut active_size = count;
    while active_size > 1 {
        values.swap(0, active_size - 1);
        active_size -= 1;
        sift_down(&mut values, &mut reverse, active_size);
    }

    let mut checksum = 0i64;
    for index in 0..count { checksum += (index as i64 + 1) * (values[index] + 1001); }
    Ok(checksum)
}

#[no_mangle]
pub unsafe extern "C" fn weak_heapsort(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_INPUT_LENGTH { return -1; }
    execute(std::slice::from_raw_parts(input, length)).unwrap_or(-1)
}
