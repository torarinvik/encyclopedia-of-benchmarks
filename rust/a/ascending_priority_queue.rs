/// Bounded linked-node pool for an ascending priority queue.
#[no_mangle]
pub extern "C" fn ascending_priority_queue(input: *const i64, length: usize) -> i64 {
    const MAX_OPERATIONS: i64 = 512;
    const CAPACITY: usize = 64;
    if input.is_null() || length < 1 { return -1; }
    let operation_count = unsafe { *input };
    if !(0..=MAX_OPERATIONS).contains(&operation_count) || length != 1 + 2 * operation_count as usize {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, length) };

    let mut node_values = [0i64; CAPACITY];
    let mut node_next = [0i32; CAPACITY];
    for index in 0..CAPACITY - 1 { node_next[index] = (index + 1) as i32; }
    node_next[CAPACITY - 1] = -1;
    let mut free_head = 0i32;
    let mut front = -1i32;
    let mut rear = -1i32;
    let mut checksum = 0i64;

    for operation in 0..operation_count as usize {
        let opcode = input[1 + 2 * operation];
        let payload = input[2 + 2 * operation];
        if opcode == 0 {
            if !(-1_000_000..=1_000_000).contains(&payload) || free_head < 0 { return -1; }
            let node = free_head as usize;
            free_head = node_next[node];
            node_values[node] = payload;
            node_next[node] = -1;
            if front < 0 { front = node as i32; rear = node as i32; }
            else { node_next[rear as usize] = node as i32; rear = node as i32; }
        } else if opcode == 1 {
            if payload != 0 || front < 0 { return -1; }
            let (mut previous, mut current) = (-1i32, front);
            let (mut minimum, mut minimum_previous) = (front, -1i32);
            while current >= 0 {
                if node_values[current as usize] < node_values[minimum as usize] {
                    minimum = current;
                    minimum_previous = previous;
                }
                previous = current;
                current = node_next[current as usize];
            }
            checksum += (operation as i64 + 1) * (node_values[minimum as usize] + 1_000_001);
            if minimum_previous < 0 { front = node_next[minimum as usize]; }
            else { node_next[minimum_previous as usize] = node_next[minimum as usize]; }
            if rear == minimum { rear = minimum_previous; }
            node_next[minimum as usize] = free_head;
            free_head = minimum;
        } else { return -1; }
    }

    let mut position = 1i64;
    let mut current = front;
    while current >= 0 {
        checksum += position * (node_values[current as usize] + 1_000_001);
        current = node_next[current as usize];
        position += 1;
    }
    checksum
}
