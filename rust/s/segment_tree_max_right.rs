/// Point updates and sum-monoid max_right boundary searches.
#[no_mangle]
pub extern "C" fn segment_tree_max_right(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(2..=55).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=16).contains(&input[0]) || !(0..=12).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let operations = input[1] as usize;
    if length != 2 + n + 3 * operations { return -1; }

    let mut tree = [0i64; 64];
    let mut size = 1usize;
    while size < n { size *= 2; }
    for i in 0..n {
        let value = input[2 + i];
        if !(0..=1000).contains(&value) { return -1; }
        tree[size + i] = value;
    }
    let mut node = size;
    while node > 1 {
        node -= 1;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    let mut query_index = 0usize;
    let mut result = 0i64;
    let mut cursor = 2 + n;
    for _ in 0..operations {
        let opcode = input[cursor];
        let first = input[cursor + 1];
        let second = input[cursor + 2];
        cursor += 3;
        if opcode == 0 {
            if first < 0 || first >= n as i64 || !(0..=1000).contains(&second) { return -1; }
            node = size + first as usize;
            tree[node] = second;
            while node > 1 {
                node /= 2;
                tree[node] = tree[2 * node] + tree[2 * node + 1];
            }
        } else if opcode == 1 {
            if first < 0 || first > n as i64 || !(0..=16000).contains(&second) { return -1; }
            let left = first as usize;
            let mut boundary = n;
            if left < n {
                let mut position = left + size;
                let mut accumulated = 0i64;
                let mut done = false;
                while !done {
                    while position & 1 == 0 { position /= 2; }
                    if accumulated + tree[position] > second {
                        while position < size {
                            position *= 2;
                            if accumulated + tree[position] <= second {
                                accumulated += tree[position];
                                position += 1;
                            }
                        }
                        boundary = (position - size).min(n);
                        done = true;
                    } else {
                        accumulated += tree[position];
                        position += 1;
                        if position & (position - 1) == 0 { done = true; }
                    }
                }
            }
            result |= (boundary as i64) << (5 * query_index);
            query_index += 1;
        } else {
            return -1;
        }
    }
    result
}
