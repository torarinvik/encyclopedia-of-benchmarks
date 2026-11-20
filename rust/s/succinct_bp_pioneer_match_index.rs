const MAX_BITS: usize = 64;
const BLOCK_BITS: usize = 8;
const BASE_BITS: usize = 16;
const LEVELS: usize = 3;
const MAX_INPUT: usize = 66;

#[derive(Clone, Copy, Default)]
struct Group { key: u16, start: u8, count: u8, cursor: u8 }

#[derive(Clone, Copy)]
struct Level {
    length: usize,
    bits: [u8; MAX_BITS],
    mate: [u8; MAX_BITS],
    far: [u8; MAX_BITS],
    family: [u8; MAX_BITS],
    family_rank: [i16; MAX_BITS],
    depth: [i16; MAX_BITS + 1],
    open_pioneer: [u8; MAX_BITS],
    close_pioneer: [u8; MAX_BITS],
    open_groups: [Group; MAX_BITS],
    close_groups: [Group; MAX_BITS],
    open_members: [u8; MAX_BITS],
    close_members: [u8; MAX_BITS],
    open_group_count: usize,
    close_group_count: usize,
}

impl Default for Level {
    fn default() -> Self {
        Self {
            length: 0, bits: [0; MAX_BITS], mate: [0; MAX_BITS], far: [0; MAX_BITS],
            family: [0; MAX_BITS], family_rank: [-1; MAX_BITS], depth: [0; MAX_BITS + 1],
            open_pioneer: [0; MAX_BITS], close_pioneer: [0; MAX_BITS],
            open_groups: [Group::default(); MAX_BITS], close_groups: [Group::default(); MAX_BITS],
            open_members: [0; MAX_BITS], close_members: [0; MAX_BITS],
            open_group_count: 0, close_group_count: 0,
        }
    }
}

struct State { levels: [Level; LEVELS] }

impl Default for State {
    fn default() -> Self { Self { levels: std::array::from_fn(|_| Level::default()) } }
}

fn group_key(source: usize, target: usize, depth: i16) -> u16 {
    ((source << 10) | (target << 7) | depth as usize) as u16
}

fn find_group(groups: &[Group; MAX_BITS], count: usize, key: u16) -> Option<usize> {
    (0..count).find(|&i| groups[i].key == key)
}

fn build_groups(level: &mut Level, targets: &[i16; MAX_BITS]) {
    for position in 0..level.length {
        if level.far[position] == 0 { continue; }
        let source = position / BLOCK_BITS;
        let target = targets[position] as usize;
        let depth = if level.bits[position] != 0 { level.depth[position] } else { level.depth[position + 1] };
        let key = group_key(source, target, depth);
        if level.bits[position] != 0 {
            let index = find_group(&level.open_groups, level.open_group_count, key).unwrap_or_else(|| {
                let i = level.open_group_count;
                level.open_group_count += 1;
                level.open_groups[i].key = key;
                i
            });
            level.open_groups[index].count += 1;
        } else {
            let index = find_group(&level.close_groups, level.close_group_count, key).unwrap_or_else(|| {
                let i = level.close_group_count;
                level.close_group_count += 1;
                level.close_groups[i].key = key;
                i
            });
            level.close_groups[index].count += 1;
        }
    }
    let mut offset = 0usize;
    for group in &mut level.open_groups[..level.open_group_count] {
        group.start = offset as u8; group.cursor = 0; offset += group.count as usize;
    }
    offset = 0;
    for group in &mut level.close_groups[..level.close_group_count] {
        group.start = offset as u8; group.cursor = 0; offset += group.count as usize;
    }
    for position in 0..level.length {
        if level.far[position] == 0 { continue; }
        let source = position / BLOCK_BITS;
        let target = targets[position] as usize;
        let depth = if level.bits[position] != 0 { level.depth[position] } else { level.depth[position + 1] };
        let key = group_key(source, target, depth);
        if level.bits[position] != 0 {
            let index = find_group(&level.open_groups, level.open_group_count, key).unwrap();
            let group = level.open_groups[index];
            let slot = group.start as usize + group.cursor as usize;
            level.open_members[slot] = position as u8;
            level.open_groups[index].cursor += 1;
        } else {
            let index = find_group(&level.close_groups, level.close_group_count, key).unwrap();
            let group = level.close_groups[index];
            let slot = group.start as usize + group.cursor as usize;
            level.close_members[slot] = position as u8;
            level.close_groups[index].cursor += 1;
        }
    }
}

fn build_level(state: &mut State, level_id: usize, bits: &[u8; MAX_BITS], length: usize) -> bool {
    if level_id >= LEVELS || length > MAX_BITS { return false; }
    let mut stack = [0usize; MAX_BITS];
    let mut matched = [0u8; MAX_BITS];
    let mut targets = [-1i16; MAX_BITS];
    let mut top = 0usize;
    {
        let a = &mut state.levels[level_id];
        a.length = length;
        a.open_group_count = 0; a.close_group_count = 0;
        for i in 0..length {
            a.bits[i] = bits[i]; a.mate[i] = 0; a.far[i] = 0; a.family[i] = 0;
            a.family_rank[i] = -1; a.open_pioneer[i] = 0; a.close_pioneer[i] = 0;
            if bits[i] != 0 { stack[top] = i; top += 1; }
            else {
                if top == 0 { return false; }
                top -= 1;
                matched[stack[top]] = i as u8; matched[i] = stack[top] as u8;
            }
        }
        if top != 0 { return false; }
        a.depth[0] = 0;
        for i in 0..length { a.depth[i + 1] = a.depth[i] + if bits[i] != 0 { 1 } else { -1 }; }
        if length <= BASE_BITS {
            a.mate[..length].copy_from_slice(&matched[..length]);
            return true;
        }
        for i in 0..length {
            let target = matched[i] as usize / BLOCK_BITS;
            if target == i / BLOCK_BITS { a.mate[i] = matched[i]; }
            else { a.far[i] = 1; targets[i] = target as i16; }
        }
        build_groups(a, &targets);

        for start in (0..length).step_by(BLOCK_BITS) {
            let end = (start + BLOCK_BITS).min(length);
            let mut previous = -1i16;
            for i in start..end {
                if bits[i] == 0 || a.far[i] == 0 { continue; }
                if previous < 0 || targets[i] != previous { a.open_pioneer[i] = 1; }
                previous = targets[i];
            }
            let mut next = -1i16;
            for i in (start..end).rev() {
                if bits[i] != 0 || a.far[i] == 0 { continue; }
                if next < 0 || targets[i] != next { a.close_pioneer[i] = 1; }
                next = targets[i];
            }
        }
        for i in 0..length {
            if a.open_pioneer[i] != 0 || a.close_pioneer[i] != 0 {
                a.family[i] = 1; a.family[matched[i] as usize] = 1;
            }
        }
    }
    let mut child = [0u8; MAX_BITS];
    let mut count = 0usize;
    {
        let a = &mut state.levels[level_id];
        for i in 0..length {
            if a.family[i] != 0 {
                a.family_rank[i] = count as i16;
                child[count] = a.bits[i]; count += 1;
            }
        }
    }
    count > 0 && count < length && build_level(state, level_id + 1, &child, count)
}

fn find_pioneer(a: &Level, position: usize) -> Option<usize> {
    let start = (position / BLOCK_BITS) * BLOCK_BITS;
    if a.bits[position] != 0 {
        (start..=position).rev().find(|&i| a.open_pioneer[i] != 0)
    } else {
        let end = (start + BLOCK_BITS).min(a.length);
        (position..end).find(|&i| a.close_pioneer[i] != 0)
    }
}

fn match_position(state: &State, level_id: usize, position: usize) -> Option<usize> {
    let a = &state.levels[level_id];
    if position >= a.length { return None; }
    if a.length <= BASE_BITS || a.far[position] == 0 { return Some(a.mate[position] as usize); }
    let pioneer = find_pioneer(a, position)?;
    let child_match = match_position(state, level_id + 1, a.family_rank[pioneer] as usize)?;
    let anchor = a.family[child_match] as usize;
    let source = position / BLOCK_BITS;
    let target = anchor / BLOCK_BITS;
    let target_depth;
    if a.bits[position] != 0 {
        let delta = a.depth[position] - a.depth[pioneer];
        target_depth = a.depth[pioneer] + delta;
        let left_i = find_group(&a.open_groups, a.open_group_count, group_key(source, target, target_depth))?;
        let right_i = find_group(&a.close_groups, a.close_group_count, group_key(target, source, target_depth))?;
        let left = a.open_groups[left_i]; let right = a.close_groups[right_i];
        let rank = (0..left.count as usize).find(|&r| a.open_members[left.start as usize + r] as usize == position)?;
        Some(a.close_members[right.start as usize + rank] as usize)
    } else {
        let delta = a.depth[position + 1] - a.depth[pioneer + 1];
        target_depth = a.depth[pioneer + 1] + delta;
        let left_i = find_group(&a.close_groups, a.close_group_count, group_key(source, target, target_depth))?;
        let right_i = find_group(&a.open_groups, a.open_group_count, group_key(target, source, target_depth))?;
        let left = a.close_groups[left_i]; let right = a.open_groups[right_i];
        let rank = (0..left.count as usize).find(|&r| a.close_members[left.start as usize + r] as usize == position)?;
        Some(a.open_members[right.start as usize + rank] as usize)
    }
}

fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { unsafe { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; } }
}

#[no_mangle]
pub unsafe extern "C" fn succinct_bp_pioneer_match_index(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 3 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n = values[0];
    if !(1..=32).contains(&n) || length != 1 + 2 * n as usize { return -1; }
    let bit_count = 2 * n as usize;
    let mut bits = [0u8; MAX_BITS];
    let mut balance = 0i32;
    for i in 0..bit_count {
        if values[i + 1] != 0 && values[i + 1] != 1 { return -1; }
        bits[i] = values[i + 1] as u8;
        balance += if bits[i] != 0 { 1 } else { -1 };
        if balance < 0 { return -1; }
    }
    if balance != 0 { return -1; }
    let mut state = State::default();
    if !build_level(&mut state, 0, &bits, bit_count) { return -1; }
    let required = 8 * (1 + bit_count);
    if output.is_null() || capacity < required { return -2; }
    let mut words = [0i64; 1 + MAX_BITS];
    words[0] = bit_count as i64;
    for i in 0..bit_count {
        words[i + 1] = match match_position(&state, 0, i) { Some(value) => value as i64, None => return -1 };
    }
    for i in 0..1 + bit_count { write_i64_le(output, 8 * i, words[i]); }
    required as i64
}
