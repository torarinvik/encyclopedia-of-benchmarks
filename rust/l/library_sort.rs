/// Bounded port of the pinned Java Library Sort gap-insertion routine.
const MAX_ITEMS: usize = 256;
const MAX_CAPACITY: usize = 2 * MAX_ITEMS;
const I32_MAX: i64 = 2_147_483_647;

fn find_insertion_index(data: &[i64; MAX_CAPACITY], occupied: &[bool; MAX_CAPACITY],
                        capacity: usize, value: i64) -> usize {
    let mut low = 0;
    let mut high = capacity;
    while low < high {
        let middle = low + (high - low) / 2;
        let mut probe = I32_MAX;
        for index in middle..capacity {
            if occupied[index] {
                probe = data[index];
                break;
            }
        }
        if probe != I32_MAX && probe <= value { low = middle + 1; }
        else { high = middle; }
    }
    low
}

fn insert_at_end(data: &mut [i64; MAX_CAPACITY], occupied: &mut [bool; MAX_CAPACITY],
                 capacity: usize, value: i64) {
    let last = capacity - 1;
    let mut left = last as isize - 1;
    while left >= 0 && occupied[left as usize] { left -= 1; }
    if left < 0 { return; }
    for index in left as usize..last { data[index] = data[index + 1]; }
    occupied[left as usize] = true;
    data[last] = value;
}

fn insert_value(data: &mut [i64; MAX_CAPACITY], occupied: &mut [bool; MAX_CAPACITY],
                capacity: usize, value: i64) {
    let position = find_insertion_index(data, occupied, capacity, value);
    if position >= capacity {
        insert_at_end(data, occupied, capacity, value);
        return;
    }
    if !occupied[position] {
        data[position] = value;
        occupied[position] = true;
        return;
    }

    let mut right = position;
    while right < capacity && occupied[right] { right += 1; }
    let mut left = position as isize - 1;
    while left >= 0 && occupied[left as usize] { left -= 1; }
    let can_go_right = right < capacity;
    let can_go_left = left >= 0;
    if can_go_right && (!can_go_left || right - position <= position - left as usize) {
        for index in (position + 1..=right).rev() { data[index] = data[index - 1]; }
        occupied[right] = true;
        data[position] = value;
    } else if can_go_left {
        let gap = left as usize;
        for index in gap..position - 1 { data[index] = data[index + 1]; }
        occupied[gap] = true;
        data[position - 1] = value;
    }
}

#[no_mangle]
pub extern "C" fn library_sort(values: *mut i64, length: usize) {
    if values.is_null() || length < 2 || length > MAX_ITEMS { return; }
    let values = unsafe { std::slice::from_raw_parts_mut(values, length) };
    let capacity = 2 * length;
    let mut data = [0_i64; MAX_CAPACITY];
    let mut temporary = [0_i64; MAX_ITEMS];
    let mut occupied = [false; MAX_CAPACITY];
    let mut filled = 1;
    let mut next = 1;
    let mut round = 0;
    let middle = capacity / 2;
    data[middle] = values[0];
    occupied[middle] = true;

    while next < length {
        let batch = (1_usize << round).min(length - next);
        for index in 0..batch {
            insert_value(&mut data, &mut occupied, capacity, values[next + index]);
            filled += 1;
        }
        next += batch;
        round += 1;
        if next < length {
            let mut at = 0;
            for index in 0..capacity {
                if occupied[index] { temporary[at] = data[index]; at += 1; }
            }
            occupied[..capacity].fill(false);
            for index in 0..filled {
                let slot = index * capacity / filled;
                data[slot] = temporary[index];
                occupied[slot] = true;
            }
        }
    }

    let mut output = 0;
    for index in 0..capacity {
        if occupied[index] { values[output] = data[index]; output += 1; }
    }
}
