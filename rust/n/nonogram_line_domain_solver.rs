const MAX_SIDE: usize = 8;
const MAX_LINES: usize = 16;
type Domains = [u64; MAX_LINES * 4];

struct Parsed {
    height: usize,
    width: usize,
    clues: [[i64; 4]; MAX_LINES],
    counts: [usize; MAX_LINES],
}

fn parse(input: &[i64]) -> Option<Parsed> {
    if input.len() < 2 || !(1..=MAX_SIDE as i64).contains(&input[0]) ||
        !(1..=MAX_SIDE as i64).contains(&input[1]) { return None; }
    let height = input[0] as usize;
    let width = input[1] as usize;
    if input.len() != 2 + 5 * height + 5 * width { return None; }
    let mut clues = [[0i64; 4]; MAX_LINES];
    let mut counts = [0usize; MAX_LINES];
    let mut offset = 2;
    for group in 0..2 {
        let lines = if group == 0 { height } else { width };
        let line_length = if group == 0 { width } else { height };
        for line in 0..lines {
            let index = if group == 0 { line } else { height + line };
            let count = input[offset]; offset += 1;
            if !(0..=4).contains(&count) { return None; }
            counts[index] = count as usize;
            let mut needed = if count == 0 { 0 } else { count - 1 };
            for run in 0..4 {
                let value = input[offset]; offset += 1;
                if run < counts[index] {
                    if value <= 0 || value > line_length as i64 { return None; }
                    clues[index][run] = value;
                    needed += value;
                } else if value != 0 { return None; }
            }
            if needed > line_length as i64 { return None; }
        }
    }
    let row_total: i64 = (0..height).map(|r| clues[r][..counts[r]].iter().sum::<i64>()).sum();
    let col_total: i64 = (0..width).map(|c| {
        let i = height + c;
        clues[i][..counts[i]].iter().sum::<i64>()
    }).sum();
    if row_total != col_total { return None; }
    Some(Parsed { height, width, clues, counts })
}

fn matches(mask: usize, length: usize, clue: &[i64], count: usize) -> bool {
    let mut found = 0;
    let mut run = 0;
    for bit in 0..length {
        if (mask >> bit) & 1 != 0 { run += 1; }
        else if run != 0 {
            if found >= count || clue[found] != run as i64 { return false; }
            found += 1; run = 0;
        }
    }
    if run != 0 {
        if found >= count || clue[found] != run as i64 { return false; }
        found += 1;
    }
    found == count
}
fn has(domains: &Domains, line: usize, mask: usize) -> bool {
    domains[line * 4 + mask / 64] & (1u64 << (mask % 64)) != 0
}
fn add(domains: &mut Domains, line: usize, mask: usize) {
    domains[line * 4 + mask / 64] |= 1u64 << (mask % 64);
}
fn count(domains: &Domains, line: usize, length: usize) -> usize {
    (0..(1usize << length)).filter(|&mask| has(domains, line, mask)).count()
}
fn filter(domains: &mut Domains, line: usize, length: usize, pos: usize,
          allow_zero: bool, allow_one: bool) -> bool {
    let mut changed = false;
    for mask in 0..(1usize << length) {
        if !has(domains, line, mask) { continue; }
        let one = (mask >> pos) & 1 != 0;
        let supported = if one { allow_one } else { allow_zero };
        if supported { continue; }
        domains[line * 4 + mask / 64] &= !(1u64 << (mask % 64));
        changed = true;
    }
    changed
}
fn support(domains: &Domains, line: usize, length: usize, pos: usize) -> Option<(bool, bool)> {
    let (mut zero, mut one) = (false, false);
    for mask in 0..(1usize << length) {
        if !has(domains, line, mask) { continue; }
        if (mask >> pos) & 1 != 0 { one = true; } else { zero = true; }
    }
    if zero || one { Some((zero, one)) } else { None }
}
fn propagate(domains: &mut Domains, height: usize, width: usize) -> bool {
    loop {
        let mut changed = false;
        for row in 0..height {
            for col in 0..width {
                let Some((rz, ro)) = support(domains, row, width, col) else { return false; };
                let Some((cz, co)) = support(domains, height + col, height, row) else { return false; };
                changed |= filter(domains, row, width, col, cz, co);
                changed |= filter(domains, height + col, height, row, rz, ro);
                if count(domains, row, width) == 0 || count(domains, height + col, height) == 0 { return false; }
            }
        }
        if !changed { return true; }
    }
}
fn search(domains: &mut Domains, height: usize, width: usize) -> bool {
    if !propagate(domains, height, width) { return false; }
    let branch = (0..height).find(|&r| count(domains, r, width) > 1);
    let Some(row) = branch else { return true; };
    for mask in 0..(1usize << width) {
        if !has(domains, row, mask) { continue; }
        let mut trial = *domains;
        trial[row * 4..row * 4 + 4].fill(0);
        add(&mut trial, row, mask);
        if search(&mut trial, height, width) { *domains = trial; return true; }
    }
    false
}
fn solve(parsed: &Parsed) -> Option<Vec<u8>> {
    let (height, width) = (parsed.height, parsed.width);
    let mut domains = [0u64; MAX_LINES * 4];
    for row in 0..height {
        for mask in 0..(1usize << width) {
            if matches(mask, width, &parsed.clues[row], parsed.counts[row]) { add(&mut domains, row, mask); }
        }
    }
    for col in 0..width {
        let line = height + col;
        for mask in 0..(1usize << height) {
            if matches(mask, height, &parsed.clues[line], parsed.counts[line]) { add(&mut domains, line, mask); }
        }
    }
    if !(0..height).all(|r| count(&domains, r, width) != 0) ||
       !(0..width).all(|c| count(&domains, height + c, height) != 0) ||
       !search(&mut domains, height, width) { return None; }
    let mut output = Vec::with_capacity(height * width);
    for row in 0..height {
        let mask = (0..(1usize << width)).find(|&m| has(&domains, row, m))?;
        for col in 0..width { output.push(((mask >> col) & 1) as u8); }
    }
    Some(output)
}

fn call(input: &[i64], output: Option<&mut [u8]>) -> i64 {
    let Some(parsed) = parse(input) else { return -1; };
    let Some(result) = solve(&parsed) else { return -1; };
    let Some(buffer) = output else { return -2; };
    if buffer.len() < result.len() { return -2; }
    buffer[..result.len()].copy_from_slice(&result);
    result.len() as i64
}

#[no_mangle]
pub unsafe extern "C" fn nonogram_line_domain_solver(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length > 82 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let parsed = match parse(values) { Some(p) => p, None => return -1 };
    let result = match solve(&parsed) { Some(v) => v, None => return -1 };
    if output.is_null() || output_capacity < result.len() { return -2; }
    let buffer = std::slice::from_raw_parts_mut(output, output_capacity);
    buffer[..result.len()].copy_from_slice(&result);
    result.len() as i64
}
