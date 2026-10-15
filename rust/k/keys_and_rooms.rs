/// Return whether every room is reachable from room zero.
#[no_mangle]
pub extern "C" fn keys_and_rooms(values: *const i64, length: usize) -> i64 {
    const MAX_ROOMS: usize = 1000;
    const MAX_INPUT_LENGTH: usize = 100001;
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return -1; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < 2 || values[0] > MAX_ROOMS as i64 { return -1; }
    let room_count = values[0] as usize;
    let mut starts = [0usize; MAX_ROOMS];
    let mut degrees = [0usize; MAX_ROOMS];
    let mut cursor = 1usize;

    for room in 0..room_count {
        if cursor >= length { return -1; }
        let count_value = values[cursor];
        cursor += 1;
        if count_value < 0 || count_value > room_count as i64 { return -1; }
        let degree = count_value as usize;
        if degree > length - cursor { return -1; }
        starts[room] = cursor;
        degrees[room] = degree;
        for &key in &values[cursor..cursor + degree] {
            if key < 0 || key >= room_count as i64 { return -1; }
        }
        cursor += degree;
    }
    if cursor != length { return -1; }

    let mut visited = [false; MAX_ROOMS];
    let mut stack = [0usize; MAX_ROOMS];
    let mut stack_size = 1usize;
    let mut reached = 0usize;
    stack[0] = 0;
    visited[0] = true;
    while stack_size > 0 {
        stack_size -= 1;
        let room = stack[stack_size];
        reached += 1;
        for edge in 0..degrees[room] {
            let key = values[starts[room] + edge] as usize;
            if !visited[key] {
                visited[key] = true;
                stack[stack_size] = key;
                stack_size += 1;
            }
        }
    }
    if reached == room_count { 1 } else { 0 }
}
