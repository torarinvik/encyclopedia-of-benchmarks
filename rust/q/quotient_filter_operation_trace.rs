const SLOTS: usize = 8;
const MAX_OPS: usize = 32;
const MAX_ITEMS: usize = 6;

fn next_slot(i: usize) -> usize { (i + 1) % SLOTS }
fn prev_slot(i: usize) -> usize { (i + SLOTS - 1) % SLOTS }

fn empty_slot(i: usize, rem: &[u8; SLOTS], occ: &[bool; SLOTS],
        cont: &[bool; SLOTS], shifted: &[bool; SLOTS]) -> bool {
    rem[i] == 0 && !occ[i] && !cont[i] && !shifted[i]
}

fn find_run(q: usize, occ: &[bool; SLOTS], cont: &[bool; SLOTS],
        shifted: &[bool; SLOTS]) -> Result<Option<usize>, ()> {
    if !occ[q] { return Ok(None); }
    let mut bucket = q;
    let mut steps = 0;
    while shifted[bucket] && steps < SLOTS {
        bucket = prev_slot(bucket);
        steps += 1;
    }
    if steps >= SLOTS { return Err(()); }
    let mut slot = bucket;
    while bucket != q {
        slot = next_slot(slot);
        steps = 0;
        while cont[slot] && steps < SLOTS { slot = next_slot(slot); steps += 1; }
        if steps >= SLOTS { return Err(()); }
        bucket = next_slot(bucket);
        steps = 0;
        while !occ[bucket] && steps < SLOTS { bucket = next_slot(bucket); steps += 1; }
        if steps >= SLOTS { return Err(()); }
    }
    Ok(Some(slot))
}

fn find_insert_position(q: usize, occ: &[bool; SLOTS], cont: &[bool; SLOTS],
        shifted: &[bool; SLOTS]) -> Result<usize, ()> {
    let mut bucket = q;
    let mut steps = 0;
    while shifted[bucket] && steps < SLOTS { bucket = prev_slot(bucket); steps += 1; }
    if steps >= SLOTS { return Err(()); }
    let mut slot = bucket;
    while bucket != q {
        steps = 0;
        loop {
            slot = next_slot(slot);
            steps += 1;
            if !cont[slot] || steps >= SLOTS { break; }
        }
        if steps >= SLOTS { return Err(()); }
        bucket = next_slot(bucket);
        steps = 0;
        while bucket != q && !occ[bucket] && steps < SLOTS {
            bucket = next_slot(bucket);
            steps += 1;
        }
        if steps >= SLOTS { return Err(()); }
    }
    Ok(slot)
}

fn next_occupied(q: usize, occ: &[bool; SLOTS]) -> Option<usize> {
    let mut bucket = next_slot(q);
    for _ in 0..SLOTS {
        if occ[bucket] { return Some(bucket); }
        bucket = next_slot(bucket);
    }
    None
}

fn insert_at(position: usize, q: usize, r: u8, has_run: bool, run_start: usize,
        rem: &mut [u8; SLOTS], occ: &mut [bool; SLOTS], cont: &mut [bool; SLOTS],
        shifted: &mut [bool; SLOTS]) -> bool {
    let new_cont = has_run && position != run_start;
    if has_run && position == run_start { cont[position] = true; }
    let mut empty = position;
    let mut found_empty = false;
    for _ in 0..SLOTS {
        if empty_slot(empty, rem, occ, cont, shifted) { found_empty = true; break; }
        empty = next_slot(empty);
    }
    if !found_empty { return false; }
    let mut slot = empty;
    while slot != position {
        let previous = prev_slot(slot);
        rem[slot] = rem[previous];
        cont[slot] = cont[previous];
        shifted[slot] = true;
        slot = previous;
    }
    rem[position] = r;
    cont[position] = new_cont;
    shifted[position] = position != q;
    occ[q] = true;
    true
}

fn run(values: &[i64]) -> Result<[u8; MAX_OPS], i64> {
    let count = values[0] as usize;
    let mut rem = [0u8; SLOTS];
    let mut occ = [false; SLOTS];
    let mut cont = [false; SLOTS];
    let mut shifted = [false; SLOTS];
    let mut total = 0usize;
    let mut statuses = [0u8; MAX_OPS];

    for op in 0..count {
        let opcode = values[1 + 2 * op];
        let fp = values[2 + 2 * op] as usize;
        let q = fp >> 5;
        let r = (fp & 31) as u8;
        if opcode == 0 {
            if total == MAX_ITEMS { statuses[op] = 2; continue; }
            let mut position;
            let mut run_start = 0;
            match find_run(q, &occ, &cont, &shifted) {
                Err(()) => return Err(-1),
                Ok(Some(start)) => {
                    position = start;
                    run_start = start;
                    for _ in 0..SLOTS {
                        if rem[position] > r { break; }
                        let next = next_slot(position);
                        position = next;
                        if !cont[next] { break; }
                    }
                }
                Ok(None) if empty_slot(q, &rem, &occ, &cont, &shifted) => position = q,
                Ok(None) => {
                    match find_insert_position(q, &occ, &cont, &shifted) {
                        Ok(found) => position = found,
                        Err(()) => return Err(-1),
                    }
                }
            }
            let has_run = occ[q];
            if !insert_at(position, q, r, has_run, run_start,
                    &mut rem, &mut occ, &mut cont, &mut shifted) { return Err(-1); }
            total += 1;
            statuses[op] = 1;
        } else if opcode == 1 {
            let start = match find_run(q, &occ, &cont, &shifted) {
                Err(()) => return Err(-1),
                Ok(value) => value,
            };
            let mut found = false;
            if let Some(mut position) = start {
                for _ in 0..SLOTS {
                    if rem[position] == r { found = true; break; }
                    if rem[position] > r { break; }
                    let next = next_slot(position);
                    if !cont[next] { break; }
                    position = next;
                }
            }
            statuses[op] = u8::from(found);
        } else {
            let start = match find_run(q, &occ, &cont, &shifted) {
                Err(()) => return Err(-1),
                Ok(value) => value,
            };
            let mut found_position = None;
            if let Some(mut position) = start {
                for _ in 0..SLOTS {
                    if rem[position] == r { found_position = Some(position); break; }
                    if rem[position] > r { break; }
                    let next = next_slot(position);
                    if !cont[next] { break; }
                    position = next;
                }
            }
            let Some(position) = found_position else { statuses[op] = 0; continue; };
            let was_run_start = !cont[position];
            let following = next_slot(position);
            let has_more_same = !empty_slot(following, &rem, &occ, &cont, &shifted)
                    && cont[following];
            if was_run_start && !has_more_same { occ[q] = false; }
            rem[position] = 0;
            cont[position] = false;
            shifted[position] = false;
            let mut hole = position;
            let mut current_q = q;
            let mut first_shift = true;
            for _ in 0..SLOTS - 1 {
                let next = next_slot(hole);
                if empty_slot(next, &rem, &occ, &cont, &shifted) || !shifted[next] { break; }
                let source_cont = cont[next];
                let promote = first_shift && was_run_start && has_more_same;
                if !source_cont && !promote {
                    current_q = match next_occupied(current_q, &occ) {
                        Some(value) => value,
                        None => return Err(-1),
                    };
                }
                rem[hole] = rem[next];
                cont[hole] = if promote { false } else { source_cont };
                shifted[hole] = cont[hole] || hole != current_q;
                rem[next] = 0;
                cont[next] = false;
                shifted[next] = false;
                hole = next;
                first_shift = false;
            }
            rem[hole] = 0;
            cont[hole] = false;
            shifted[hole] = false;
            total -= 1;
            statuses[op] = 1;
        }
    }
    Ok(statuses)
}

#[no_mangle]
pub unsafe extern "C" fn quotient_filter_operation_trace(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=66).contains(&length) { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let raw_count = values[0];
    if !(0..=MAX_OPS as i64).contains(&raw_count) || length != 1 + 2 * raw_count as usize { return -1; }
    for op in 0..raw_count as usize {
        let opcode = values[1 + 2 * op];
        let fp = values[2 + 2 * op];
        if !(0..=2).contains(&opcode) || !(0..=255).contains(&fp) { return -1; }
    }
    if output.is_null() || capacity < raw_count as usize { return -2; }
    let statuses = match run(values) { Ok(statuses) => statuses, Err(result) => return result };
    for i in 0..raw_count as usize {
        unsafe { output.add(i).write(statuses[i]); }
    }
    raw_count
}
