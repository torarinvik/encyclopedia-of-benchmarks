/// Fenwick frequency selection by binary lifting over prefix blocks.
#[no_mangle]
pub extern "C" fn fenwick_kth(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(3..=163).contains(&length) { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if !(1..=64).contains(&input[0]) || !(0..=32).contains(&input[1]) { return -1; }
    let n = input[0] as usize;
    let q = input[1] as usize;
    if length != 2 + n + 3 * q { return -1; }

    let mut frequency = [0i64; 64];
    let mut tree = [0i64; 65];
    let mut total = 0i64;
    for i in 0..n {
        let value = input[2 + i];
        if !(0..=1_000_000).contains(&value) { return -1; }
        frequency[i] = value;
        total += value;
        let index = i + 1;
        tree[index] += value;
        let parent = index + (index & (!index + 1));
        if parent <= n { tree[parent] += tree[index]; }
    }

    let mut result = 0i64;
    let mut query_number = 0usize;
    let mut cursor = 2 + n;
    for _ in 0..q {
        let opcode = input[cursor];
        let first = input[cursor + 1];
        let second = input[cursor + 2];
        cursor += 3;
        if opcode == 0 {
            if first < 0 || first >= n as i64 || !(-1_000_000..=1_000_000).contains(&second) { return -1; }
            let position = first as usize;
            let updated = frequency[position] + second;
            if !(0..=1_000_000).contains(&updated) { return -1; }
            frequency[position] = updated;
            total += second;
            let mut index = position + 1;
            while index <= n {
                tree[index] += second;
                index += index & (!index + 1);
            }
        } else if opcode == 1 {
            if second != 0 { return -1; }
            let mut answer = -1i64;
            if first > 0 && first <= total {
                let mut index = 0usize;
                let mut step = 1usize;
                while step <= n / 2 { step *= 2; }
                let mut rank = first;
                while step != 0 {
                    let candidate = index + step;
                    if candidate <= n && tree[candidate] < rank {
                        index = candidate;
                        rank -= tree[candidate];
                    }
                    step /= 2;
                }
                answer = index as i64;
            }
            result += (query_number as i64 + 1) * (answer + 1);
            query_number += 1;
        } else {
            return -1;
        }
    }
    result
}
