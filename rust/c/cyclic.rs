const MAX_NODES: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_RECORD_FIELDS: usize = 5000;

fn rotate_list(next: &[i64; MAX_NODES], previous: &[i64; MAX_NODES], head: &mut i64, size: i64, places: i64) {
    if size == 0 { return; }
    let mut steps = places % size;
    if steps < 0 { steps += size; }
    if steps > size / 2 {
        steps = size - steps;
        for _ in 0..steps { *head = previous[*head as usize]; }
    } else {
        for _ in 0..steps { *head = next[*head as usize]; }
    }
}

fn delete_head(values: &mut [i64; MAX_NODES], next: &mut [i64; MAX_NODES], previous: &mut [i64; MAX_NODES],
               head: &mut i64, size: &mut i64) -> bool {
    if *size == 0 { return false; }
    let current = *head as usize;
    if *size == 1 { *head = -1; }
    else {
        let successor = next[current] as usize;
        let predecessor = previous[current] as usize;
        next[predecessor] = successor as i64;
        previous[successor] = predecessor as i64;
        *head = successor as i64;
    }
    values[current] = 0;
    *size -= 1;
    true
}

fn add_record(records: &mut [i64; MAX_RECORD_FIELDS], field_count: &mut usize, value: i64) {
    records[*field_count] = value;
    *field_count += 1;
}

unsafe fn put_i64(output: *mut u8, offset: usize, value: i64) {
    let bytes = value.to_le_bytes();
    for i in 0..8 { *output.add(offset + i) = bytes[i]; }
}

#[no_mangle]
pub unsafe extern "C" fn cyclic(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if input[0] < 0 || input[0] > MAX_OPERATIONS as i64 { return -1; }
    let operation_count = input[0] as usize;
    if length != 1 + 2 * operation_count { return -1; }
    let mut values = [0i64; MAX_NODES];
    let mut next = [0i64; MAX_NODES];
    let mut previous = [0i64; MAX_NODES];
    let mut head = -1i64;
    let mut size = 0i64;
    let mut allocated = 0usize;
    let mut records = [0i64; MAX_RECORD_FIELDS];
    let mut record_fields = 0usize;
    let mut query_count = 0usize;

    for index in 0..operation_count {
        let operation = input[1 + 2 * index];
        let argument = input[2 + 2 * index];
        if !(0..=5).contains(&operation) { return -1; }
        if operation == 0 {
            if !(i32::MIN as i64..=i32::MAX as i64).contains(&argument) || allocated >= MAX_NODES { return -1; }
            let node = allocated;
            allocated += 1;
            values[node] = argument;
            if size == 0 { head = node as i64; next[node] = head; previous[node] = head; }
            else {
                let tail = previous[head as usize] as usize;
                previous[node] = tail as i64; next[node] = head;
                next[tail] = node as i64; previous[head as usize] = node as i64;
            }
            size += 1;
        } else if operation == 1 {
            if !(-1_000_000..=1_000_000).contains(&argument) { return -1; }
            rotate_list(&next, &previous, &mut head, size, argument);
        } else if operation == 2 {
            if argument != 0 { return -1; }
            let deleted = if delete_head(&mut values, &mut next, &mut previous, &mut head, &mut size) { 1 } else { 0 };
            add_record(&mut records, &mut record_fields, index as i64); add_record(&mut records, &mut record_fields, operation);
            add_record(&mut records, &mut record_fields, 1); add_record(&mut records, &mut record_fields, deleted); query_count += 1;
        } else if operation == 3 {
            if argument != 0 { return -1; }
            add_record(&mut records, &mut record_fields, index as i64); add_record(&mut records, &mut record_fields, operation);
            add_record(&mut records, &mut record_fields, size);
            let mut cursor = head;
            for _ in 0..size { add_record(&mut records, &mut record_fields, values[cursor as usize]); cursor = next[cursor as usize]; }
            query_count += 1;
        } else if operation == 4 {
            if !(-1_000_000..=1_000_000).contains(&argument) || size == 0 { return -1; }
            while size > 1 {
                rotate_list(&next, &previous, &mut head, size, argument);
                let _ = delete_head(&mut values, &mut next, &mut previous, &mut head, &mut size);
                rotate_list(&next, &previous, &mut head, size, -1);
            }
            let winner = values[head as usize];
            while delete_head(&mut values, &mut next, &mut previous, &mut head, &mut size) {}
            add_record(&mut records, &mut record_fields, index as i64); add_record(&mut records, &mut record_fields, operation);
            add_record(&mut records, &mut record_fields, 1); add_record(&mut records, &mut record_fields, winner); query_count += 1;
        } else {
            if argument != 0 { return -1; }
            while delete_head(&mut values, &mut next, &mut previous, &mut head, &mut size) {}
        }
    }

    let required = (1 + record_fields + 1 + size as usize) * 8;
    if output.is_null() || capacity < required { return -2; }
    let mut field = 0usize;
    put_i64(output, field * 8, query_count as i64); field += 1;
    for record in &records[..record_fields] { put_i64(output, field * 8, *record); field += 1; }
    put_i64(output, field * 8, size); field += 1;
    let mut cursor = head;
    for _ in 0..size { put_i64(output, field * 8, values[cursor as usize]); field += 1; cursor = next[cursor as usize]; }
    required as i64
}
