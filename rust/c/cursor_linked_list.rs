const CURSOR_SPACE_SIZE: usize = 100;
const MAX_OPERATIONS: usize = 64;

fn find_value(elements: &[i64; CURSOR_SPACE_SIZE], occupied: &[bool; CURSOR_SPACE_SIZE],
              next: &[i64; CURSOR_SPACE_SIZE], head: i64, value: i64) -> (i64, i64) {
    let mut previous = -1;
    let mut found = head;
    while found != -1 && (!occupied[found as usize] || elements[found as usize] != value) {
        previous = found;
        found = next[found as usize];
    }
    (previous, found)
}

fn free_node(elements: &mut [i64; CURSOR_SPACE_SIZE], occupied: &mut [bool; CURSOR_SPACE_SIZE],
             next: &mut [i64; CURSOR_SPACE_SIZE], index: usize) {
    let old_free_head = next[0];
    occupied[index] = false;
    elements[index] = 0;
    next[index] = old_free_head;
    next[0] = index as i64;
}

fn remove_value(elements: &mut [i64; CURSOR_SPACE_SIZE], occupied: &mut [bool; CURSOR_SPACE_SIZE],
                next: &mut [i64; CURSOR_SPACE_SIZE], head: &mut i64, count: &mut i64,
                value: i64) -> bool {
    if *head == -1 { return false; }
    let (previous, current) = find_value(elements, occupied, next, *head, value);
    if current == -1 { return false; }
    let successor = next[current as usize];
    if previous == -1 {
        free_node(elements, occupied, next, current as usize);
        *head = successor;
    } else {
        next[previous as usize] = successor;
        free_node(elements, occupied, next, current as usize);
    }
    *count -= 1;
    true
}

unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for i in 0..8 { *output.add(offset + i) = bytes[i]; }
}

#[no_mangle]
pub unsafe extern "C" fn cursor_linked_list(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_OPERATIONS as i64).contains(&values[0]) { return -1; }
    let operation_count = values[0] as usize;
    if length != 1 + 2 * operation_count { return -1; }
    let mut elements = [0i64; CURSOR_SPACE_SIZE];
    let mut next = [0i64; CURSOR_SPACE_SIZE];
    let mut occupied = [false; CURSOR_SPACE_SIZE];
    for i in 0..CURSOR_SPACE_SIZE { next[i] = i as i64 + 1; }
    next[CURSOR_SPACE_SIZE - 1] = 0;
    let mut head = -1i64;
    let mut count = 0i64;
    let mut query_found = [0i64; MAX_OPERATIONS];
    let mut query_values = [0i64; MAX_OPERATIONS];
    let mut query_count = 0usize;

    for index in 0..operation_count {
        let operation = values[1 + 2 * index];
        let argument = values[2 + 2 * index];
        if !(0..=4).contains(&operation) || !(i32::MIN as i64..=i32::MAX as i64).contains(&argument) { return -1; }
        if operation == 0 {
            let available = next[0] as usize;
            if available == 0 { return -1; }
            next[0] = next[available]; next[available] = -1;
            elements[available] = argument; occupied[available] = true;
            if head == -1 { head = available as i64; }
            else {
                let mut tail = head as usize;
                while next[tail] != -1 { tail = next[tail] as usize; }
                next[tail] = available as i64;
            }
            next[available] = -1; count += 1;
        } else if operation == 1 {
            if !remove_value(&mut elements, &mut occupied, &mut next, &mut head, &mut count, argument) { return -1; }
        } else if operation == 2 {
            if argument < 0 || argument >= count { return -1; }
            let mut cursor = head as usize;
            for _ in 0..argument as usize { cursor = next[cursor] as usize; }
            let value = elements[cursor];
            if !remove_value(&mut elements, &mut occupied, &mut next, &mut head, &mut count, value) { return -1; }
        } else if operation == 3 {
            if argument >= 0 && argument < count {
                let mut cursor = head as usize;
                for _ in 0..argument as usize { cursor = next[cursor] as usize; }
                query_found[query_count] = 1; query_values[query_count] = elements[cursor];
            }
            query_count += 1;
        } else {
            let (_, found) = find_value(&elements, &occupied, &next, head, argument);
            if found != -1 {
                let mut logical_index = 0i64;
                let mut cursor = head;
                while cursor != found { cursor = next[cursor as usize]; logical_index += 1; }
                query_found[query_count] = 1; query_values[query_count] = logical_index;
            }
            query_count += 1;
        }
    }

    let required = (1 + 2 * query_count + 2 + 3 * CURSOR_SPACE_SIZE) * 8;
    if output.is_null() || capacity < required { return -2; }
    let mut field = 0usize;
    put_i64(output, field * 8, query_count as i64); field += 1;
    for i in 0..query_count { put_i64(output, field * 8, query_found[i]); field += 1; put_i64(output, field * 8, query_values[i]); field += 1; }
    put_i64(output, field * 8, head); field += 1; put_i64(output, field * 8, count); field += 1;
    for i in 0..CURSOR_SPACE_SIZE {
        put_i64(output, field * 8, if occupied[i] { 1 } else { 0 }); field += 1;
        put_i64(output, field * 8, elements[i]); field += 1;
        put_i64(output, field * 8, next[i]); field += 1;
    }
    required as i64
}
