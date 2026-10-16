fn search(columns: usize, rows: &[u64], covered: u64, selected: u64, solutions: &mut Vec<u8>) {
    let full = (1u64 << columns) - 1;
    if covered == full { solutions.push(selected as u8); return; }
    let mut best: Option<(usize, Vec<usize>)> = None;
    for col in 0..columns {
        let bit = 1u64 << col;
        if covered & bit != 0 { continue; }
        let candidates: Vec<usize> = rows.iter().enumerate()
            .filter_map(|(i, &row)| if row & bit != 0 && row & covered == 0 { Some(i) } else { None }).collect();
        if candidates.is_empty() { return; }
        if best.as_ref().map_or(true, |(_, old)| candidates.len() < old.len()) { best = Some((col, candidates)); }
    }
    if let Some((_, candidates)) = best {
        for i in candidates { search(columns, rows, covered | rows[i], selected | (1u64 << i), solutions); }
    }
}

#[no_mangle]
pub extern "C" fn dancing_links(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 10 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let columns = values[0]; let n = values[1];
    if !(1..=8).contains(&columns) || !(0..=8).contains(&n) || length != n as usize + 2 { return -1; }
    let full = (1u64 << columns) - 1;
    let mut rows = Vec::with_capacity(n as usize);
    for &value in &values[2..] { if value <= 0 || value as u64 & !full != 0 { return -1; } rows.push(value as u64); }
    let mut solutions = Vec::new();
    search(columns as usize, &rows, 0, 0, &mut solutions);
    solutions.sort_unstable();
    if capacity < solutions.len() || (!solutions.is_empty() && output.is_null()) { return -2; }
    if !solutions.is_empty() { unsafe { std::ptr::copy_nonoverlapping(solutions.as_ptr(), output, solutions.len()); } }
    solutions.len() as i64
}
