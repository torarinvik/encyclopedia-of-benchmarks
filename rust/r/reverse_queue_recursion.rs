const MAX_QUEUE_LENGTH: usize = 32;
const MAX_INPUT_LENGTH: usize = 34;

fn reverse_queue_recursive(queue: &mut [u8], front: &mut usize, size: &mut usize) {
    if *size == 0 {
        return;
    }
    let capacity = queue.len();
    let value = queue[*front];
    *front = (*front + 1) % capacity;
    *size -= 1;
    reverse_queue_recursive(queue, front, size);
    let rear = (*front + *size) % capacity;
    queue[rear] = value;
    *size += 1;
}

#[no_mangle]
pub extern "C" fn reverse_queue_recursion(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() {
        if input_length != 1 {
            return -1;
        }
        return if output.is_null() { -2 } else { 0 };
    }
    if !(1..=MAX_INPUT_LENGTH).contains(&input_length) {
        return -1;
    }
    let input = unsafe { std::slice::from_raw_parts(input, input_length) };
    if !(0..=MAX_QUEUE_LENGTH as i64).contains(&input[0]) {
        return -1;
    }
    let queue_length = input[0] as usize;
    if input_length != queue_length + 1 {
        return -1;
    }
    if input[1..].iter().any(|&value| !(0..=255).contains(&value)) {
        return -1;
    }
    if output.is_null() || output_capacity < queue_length {
        return -2;
    }

    let mut queue = [0u8; MAX_QUEUE_LENGTH];
    for index in 0..queue_length {
        queue[index] = input[index + 1] as u8;
    }
    let mut front = 0;
    let mut size = queue_length;
    reverse_queue_recursive(&mut queue[..queue_length], &mut front, &mut size);
    for index in 0..queue_length {
        unsafe {
            *output.add(index) = queue[(front + index) % queue_length];
        }
    }
    queue_length as i64
}
