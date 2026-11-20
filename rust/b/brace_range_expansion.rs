#[derive(Clone, Copy)]
struct Plan {
    open: usize,
    close: usize,
    start: i32,
    step: i32,
    letter: bool,
    pad: usize,
    count: usize,
}

fn endpoint(p: &[i64], begin: usize, end: usize) -> Option<(i32, bool, usize, bool)> {
    let n = end.checked_sub(begin)?;
    if n == 1 && ((65..=90).contains(&p[begin]) || (97..=122).contains(&p[begin])) {
        return Some((p[begin] as i32, true, 1, p[begin] <= 90));
    }
    if !(1..=4).contains(&n) { return None; }
    let mut value = 0i32;
    for &byte in &p[begin..end] {
        if !(48..=57).contains(&byte) { return None; }
        value = value * 10 + (byte - 48) as i32;
    }
    Some((value, false, n, false))
}

fn step_value(p: &[i64], begin: usize, end: usize) -> Option<i32> {
    let mut at = begin;
    let mut sign = 1i32;
    if at < end && (p[at] == 43 || p[at] == 45) {
        if p[at] == 45 { sign = -1; }
        at += 1;
    }
    if end.checked_sub(at)? == 0 { return None; }
    let mut value = 0i32;
    for &byte in &p[at..end] {
        if !(48..=57).contains(&byte) { return None; }
        if value < 10000 {
            value = value * 10 + (byte - 48) as i32;
            if value > 10000 { value = 10000; }
        }
    }
    if value == 0 { None } else { Some(sign * value) }
}

fn make_plan(p: &[i64]) -> Option<Plan> {
    if p.is_empty() || p.len() > 64 || p.iter().any(|b| !(32..=126).contains(b)) {
        return None;
    }
    let mut open = None;
    let mut close = None;
    for (i, &byte) in p.iter().enumerate() {
        if byte == 123 {
            if open.is_some() { return None; }
            open = Some(i);
        } else if byte == 125 {
            if close.is_some() { return None; }
            close = Some(i);
        }
    }
    let open = open?;
    let close = close?;
    if close <= open || open + p.len() - close - 1 > 32 { return None; }
    let mut separators = [usize::MAX; 2];
    let mut separator_count = 0usize;
    let mut i = open + 1;
    while i + 1 < close {
        if p[i] == 46 && p[i+1] == 46 {
            if separator_count == 2 { return None; }
            separators[separator_count] = i;
            separator_count += 1;
            i += 2;
        } else { i += 1; }
    }
    if separator_count == 0 { return None; }
    let first_sep = separators[0];
    let second_sep = if separator_count == 2 { separators[1] } else { close };
    let a = endpoint(p, open+1, first_sep)?;
    let b = endpoint(p, first_sep+2, second_sep)?;
    if a.1 != b.1 || (a.1 && a.3 != b.3) { return None; }
    let step = if separator_count == 1 {
        if a.0 <= b.0 { 1 } else { -1 }
    } else {
        step_value(p, second_sep+2, close)?
    };
    if (a.0 < b.0 && step < 0) || (a.0 > b.0 && step > 0) { return None; }
    let count = (if a.0 == b.0 { 1 } else {
        if a.0 < b.0 { ((b.0-a.0)/step)+1 } else { ((a.0-b.0)/(-step))+1 }
    }) as usize;
    if count > 16 { return None; }
    let pad = if !a.1 && (p[open+1] == 48 || p[first_sep+2] == 48) {
        a.2.max(b.2)
    } else { 0 };
    Some(Plan { open, close, start: a.0, step, letter: a.1, pad, count })
}

#[no_mangle]
pub unsafe extern "C" fn brace_range_expansion(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(2..=65).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n = values[0];
    if !(1..=64).contains(&n) || length != n as usize + 1 { return -1; }
    let p = &values[1..];
    let Some(plan) = make_plan(p) else { return -1; };
    let mut staged = [0u8; 591];
    let mut out = 0usize;
    let mut value = plan.start;
    let suffix_start = plan.close + 1;
    for item in 0..plan.count {
        if item != 0 { staged[out] = 0; out += 1; }
        for &byte in &p[..plan.open] { staged[out] = byte as u8; out += 1; }
        if plan.letter {
            staged[out] = value as u8; out += 1;
        } else {
            let mut digits = [0u8; 4];
            let mut used = 0usize;
            let mut remaining = value;
            loop {
                digits[used] = (remaining % 10) as u8;
                used += 1;
                remaining /= 10;
                if remaining == 0 { break; }
            }
            while used < plan.pad { staged[out] = 48; out += 1; }
            while used > 0 { used -= 1; staged[out] = 48 + digits[used]; out += 1; }
        }
        for &byte in &p[suffix_start..] { staged[out] = byte as u8; out += 1; }
        value += plan.step;
    }
    if output.is_null() || capacity < out { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, out);
    out as i64
}
