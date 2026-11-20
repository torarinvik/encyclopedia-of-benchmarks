const MAX_INPUT: usize = 274;

#[no_mangle]
pub unsafe extern "C" fn simon_string_search(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT { return -2; }
    let values = std::slice::from_raw_parts(values, length);
    if !(0..=256).contains(&values[0]) || !(1..=16).contains(&values[1]) { return -2; }
    let n = values[0] as usize;
    let m = values[1] as usize;
    if length != 2 + n + m || values[2..].iter().any(|&x| !(0..=15).contains(&x)) { return -2; }
    let p = 2 + n;
    let mut head = [-1i32; 16];
    let mut edge_target = [0i32; 16];
    let mut edge_next = [0i32; 16];
    let mut edge_count = 0usize;
    let mut ell = -1i32;
    for i in 1..m {
        let k = ell;
        let mut cell = if k < 0 { -1 } else { head[k as usize] };
        ell = -1;
        if values[p + i] == values[p + (k + 1) as usize] {
            ell = k + 1;
        } else {
            edge_target[edge_count] = k + 1;
            edge_next[edge_count] = head[i - 1];
            head[i - 1] = edge_count as i32;
            edge_count += 1;
        }
        while cell >= 0 {
            let q = edge_target[cell as usize];
            if values[p + i] == values[p + q as usize] {
                ell = q;
            } else {
                edge_target[edge_count] = q;
                edge_next[edge_count] = head[i - 1];
                head[i - 1] = edge_count as i32;
                edge_count += 1;
            }
            cell = edge_next[cell as usize];
        }
    }
    let mut state = -1i32;
    let mut matches = 0i64;
    for j in 0..n {
        let symbol = values[2 + j];
        if state < m as i32 - 1 && values[p + (state + 1) as usize] == symbol {
            state += 1;
        } else if state >= 0 {
            let mut edge = head[state as usize];
            state = -1;
            while edge >= 0 {
                let q = edge_target[edge as usize];
                if values[p + q as usize] == symbol { state = q; break; }
                edge = edge_next[edge as usize];
            }
        }
        if state >= m as i32 - 1 {
            matches += 1;
            state = ell;
        }
    }
    matches
}
