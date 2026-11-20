const LISTS: usize = 3;
const MAX_LIST: usize = 32;
const MAX_VALUES: usize = 48;
const MAX_INPUT: usize = 3 + LISTS * MAX_LIST;

#[derive(Clone, Copy, PartialEq)]
enum Color { White, Green, Red }

unsafe fn put_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn t_threshold_three_sorted_lists(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT + 1 { return -1; }
    let mut base = [0usize; LISTS];
    let mut size = [0usize; LISTS];
    let mut at = 0usize;
    for id in 0..LISTS {
        if at >= length { return -1; }
        let raw_size = *input.add(at);
        if raw_size < 1 || raw_size > MAX_LIST as i64 { return -1; }
        size[id] = raw_size as usize;
        at += 1;
        if size[id] > length - at { return -1; }
        base[id] = at;
        for j in 0..size[id] {
            let value = *input.add(at + j);
            if value < i32::MIN as i64 || value > i32::MAX as i64
                || (j > 0 && *input.add(at + j - 1) >= value) { return -1; }
        }
        at += size[id];
    }
    if at != length { return -1; }

    let mut tails = [0i64; LISTS];
    let mut firsts = [0i64; LISTS];
    for i in 0..LISTS {
        tails[i] = *input.add(base[i] + size[i] - 1);
        firsts[i] = *input.add(base[i]);
    }
    tails.sort_unstable();
    firsts.sort_unstable();
    let maximum_candidate = tails[1];
    let mut candidate = firsts[1];

    let mut color = [Color::White; LISTS];
    let mut cursor = [1usize; LISTS];
    let mut search_base = [1usize; LISTS];
    let mut search_low = [1usize; LISTS];
    let mut search_step = [1usize; LISTS];
    let mut search_probe = [1usize; LISTS];
    let mut representative = [0usize; LISTS];
    let mut representative_present = [false; LISTS];
    for i in 0..LISTS {
        let head = *input.add(base[i]);
        if head == candidate { color[i] = Color::Green; }
        else if head > candidate {
            color[i] = Color::Red;
            representative_present[i] = true;
        }
    }

    let mut result = [0i64; MAX_VALUES];
    let mut result_count = 0usize;
    let mut round_robin = 0usize;
    while candidate <= maximum_candidate {
        let mut green_count = 0usize;
        let mut red_count = 0usize;
        let mut white_count = 0usize;
        for state in color {
            match state { Color::Green => green_count += 1,
                Color::Red => red_count += 1, Color::White => white_count += 1 }
        }
        if green_count >= 2 || red_count >= 2 {
            if green_count >= 2 { result[result_count] = candidate; result_count += 1; }
            let mut recolor_count = if white_count == 0 { 1 } else { 0 };
            for i in 0..LISTS {
                if recolor_count == 0 { break; }
                if color[i] != Color::Green { continue; }
                color[i] = Color::White;
                search_base[i] = cursor[i];
                search_low[i] = cursor[i];
                search_step[i] = 1;
                search_probe[i] = cursor[i];
                recolor_count -= 1;
            }
            for i in 0..LISTS {
                if color[i] != Color::Green { continue; }
                color[i] = Color::Red;
                representative[i] = cursor[i];
                representative_present[i] = cursor[i] < size[i];
            }
            let mut found = false;
            let mut next_candidate = i64::MAX;
            for i in 0..LISTS {
                if !representative_present[i] { continue; }
                let value = *input.add(base[i] + representative[i]);
                if !found || value < next_candidate { found = true; next_candidate = value; }
            }
            if !found { break; }
            candidate = next_candidate;
            for i in 0..LISTS {
                if color[i] != Color::Red || !representative_present[i]
                    || *input.add(base[i] + representative[i]) != candidate { continue; }
                color[i] = Color::Green;
                representative_present[i] = false;
                cursor[i] = representative[i] + 1;
                search_base[i] = cursor[i];
                search_low[i] = cursor[i];
                search_step[i] = 1;
                search_probe[i] = cursor[i];
            }
            continue;
        }

        let mut list_id = LISTS;
        for offset in 0..LISTS {
            let i = (round_robin + offset) % LISTS;
            if color[i] == Color::White { list_id = i; break; }
        }
        if list_id == LISTS { break; }
        round_robin = (list_id + 1) % LISTS;
        let probe = search_probe[list_id].min(size[list_id] - 1);
        if *input.add(base[list_id] + probe) < candidate {
            search_low[list_id] = probe + 1;
            if probe + 1 == size[list_id] {
                color[list_id] = Color::Red;
                representative[list_id] = size[list_id];
                representative_present[list_id] = false;
            } else {
                search_step[list_id] *= 2;
                search_probe[list_id] = (search_base[list_id] + search_step[list_id] - 1)
                    .min(size[list_id] - 1);
            }
            continue;
        }
        let mut low = search_low[list_id];
        let mut high = probe + 1;
        while low < high {
            let middle = low + (high - low) / 2;
            if *input.add(base[list_id] + middle) < candidate { low = middle + 1; }
            else { high = middle; }
        }
        if low < size[list_id] && *input.add(base[list_id] + low) == candidate {
            color[list_id] = Color::Green;
            cursor[list_id] = low + 1;
        } else {
            color[list_id] = Color::Red;
            representative[list_id] = low;
            representative_present[list_id] = low < size[list_id];
        }
    }

    let output_bytes = 8 * (1 + result_count);
    if output.is_null() || capacity < output_bytes { return -2; }
    put_i64_le(output, 0, result_count as i64);
    for i in 0..result_count { put_i64_le(output, 8 * (i + 1), result[i]); }
    output_bytes as i64
}
