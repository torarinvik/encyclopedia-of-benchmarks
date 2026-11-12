const MODULUS: i64 = 998_244_353;
const MAX_LENGTH: usize = 210;

#[derive(Clone, Copy)]
struct Record { priority: i64, a: i64, b: i64 }

#[no_mangle]
pub unsafe extern "C" fn point_set_range_sort_range_composite(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_LENGTH { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if input[0] < 1 || input[0] > 16 || input[1] < 1 || input[1] > 32 { return -1; }
    let n = input[0] as usize;
    let q = input[1] as usize;
    if length < 2 + 3 * n { return -1; }
    let mut records = [Record { priority: 0, a: 1, b: 0 }; 16];
    let mut seen = [0_i64; 48];
    let mut seen_count = 0;
    let mut cursor = 2;
    for i in 0..n {
        let (p, a, b) = (input[cursor], input[cursor + 1], input[cursor + 2]);
        cursor += 3;
        if p < 0 || p > 1_000_000_000 || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS { return -1; }
        if seen[..seen_count].contains(&p) { return -1; }
        seen[seen_count] = p;
        seen_count += 1;
        records[i] = Record { priority: p, a, b };
    }
    let mut checksum = 0_i64;
    let mut query_number = 0_i64;
    for _ in 0..q {
        if cursor >= length { return -1; }
        let opcode = input[cursor];
        cursor += 1;
        if opcode == 0 {
            if length - cursor < 4 { return -1; }
            let (index, p, a, b) = (input[cursor], input[cursor + 1], input[cursor + 2], input[cursor + 3]);
            cursor += 4;
            if index < 0 || index >= n as i64 || p < 0 || p > 1_000_000_000 || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS { return -1; }
            if seen[..seen_count].contains(&p) { return -1; }
            seen[seen_count] = p;
            seen_count += 1;
            records[index as usize] = Record { priority: p, a, b };
        } else if opcode == 1 {
            if length - cursor < 3 { return -1; }
            let (left, right, x) = (input[cursor], input[cursor + 1], input[cursor + 2]);
            cursor += 3;
            if left < 0 || left >= right || right > n as i64 || x < 0 || x >= MODULUS { return -1; }
            let mut answer = x;
            for record in &records[left as usize..right as usize] { answer = (record.a * answer + record.b) % MODULUS; }
            query_number += 1;
            checksum = (checksum + query_number * answer) % MODULUS;
        } else if opcode == 2 || opcode == 3 {
            if length - cursor < 2 { return -1; }
            let (left, right) = (input[cursor], input[cursor + 1]);
            cursor += 2;
            if left < 0 || left >= right || right > n as i64 { return -1; }
            for i in (left as usize + 1)..(right as usize) {
                let item = records[i];
                let mut j = i;
                while j > left as usize && if opcode == 2 { records[j - 1].priority > item.priority } else { records[j - 1].priority < item.priority } {
                    records[j] = records[j - 1];
                    j -= 1;
                }
                records[j] = item;
            }
        } else { return -1; }
    }
    if cursor == length { checksum } else { -1 }
}
