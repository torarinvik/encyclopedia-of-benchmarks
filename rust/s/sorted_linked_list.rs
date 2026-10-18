const MAX_INITIAL_COUNT: usize = 16;
const MAX_INPUT_LENGTH: usize = 20;
const MAX_OUTPUT_WORDS: usize = 18;

#[derive(Clone, Copy, Default)]
struct ListNode { value: i32, next: i32 }

#[no_mangle]
pub unsafe extern "C" fn sorted_linked_list(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 3 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 0 || values[0] > MAX_INITIAL_COUNT as i64 { return -1; }
    let count = values[0] as usize;
    if input_length != count + 3 { return -1; }

    let mut nodes = [ListNode::default(); MAX_INITIAL_COUNT + 1];
    for index in 0..count {
        let value = values[index + 1];
        if value < i32::MIN as i64 || value > i32::MAX as i64 || (index > 0 && values[index] >= value) { return -1; }
        nodes[index] = ListNode { value: value as i32, next: if index + 1 < count { (index + 1) as i32 } else { -1 } };
    }
    let operation_value = values[count + 1];
    let key_value = values[count + 2];
    if !(0..=2).contains(&operation_value) || key_value < i32::MIN as i64 || key_value > i32::MAX as i64 { return -1; }
    let operation = operation_value as usize;
    let key = key_value as i32;
    let mut head = if count == 0 { -1 } else { 0 };
    let mut tail = if count == 0 { -1 } else { count as i32 - 1 };

    if operation == 0 {
        let mut node = head;
        while node >= 0 {
            if nodes[node as usize].value == key { return -1; }
            node = nodes[node as usize].next;
        }
    }

    let mut staged = [0_i64; MAX_OUTPUT_WORDS];
    let mut word_count = 0_usize;
    if operation == 0 {
        let new_node = count as i32;
        nodes[new_node as usize] = ListNode { value: key, next: -1 };
        if head < 0 {
            head = new_node;
            tail = new_node;
        } else if key < nodes[head as usize].value {
            nodes[new_node as usize].next = head;
            head = new_node;
        } else if key > nodes[tail as usize].value {
            nodes[tail as usize].next = new_node;
            tail = new_node;
        } else {
            let mut previous = head;
            while nodes[previous as usize].next >= 0 &&
                nodes[nodes[previous as usize].next as usize].value < key {
                previous = nodes[previous as usize].next;
            }
            nodes[new_node as usize].next = nodes[previous as usize].next;
            nodes[previous as usize].next = new_node;
            if nodes[new_node as usize].next < 0 { tail = new_node; }
        }
        staged[word_count] = (count + 1) as i64;
        word_count += 1;
        let mut node = head;
        while node >= 0 {
            staged[word_count] = nodes[node as usize].value as i64;
            word_count += 1;
            node = nodes[node as usize].next;
        }
    } else if operation == 1 {
        let mut found = false;
        let mut node = head;
        while node >= 0 {
            if nodes[node as usize].value == key { found = true; break; }
            node = nodes[node as usize].next;
        }
        staged[word_count] = i64::from(found);
        word_count += 1;
    } else {
        let mut deleted = false;
        if head >= 0 && nodes[head as usize].value == key {
            head = nodes[head as usize].next;
            if head < 0 { tail = -1; }
            deleted = true;
        } else {
            let mut previous = head;
            while previous >= 0 && nodes[previous as usize].next >= 0 {
                let candidate = nodes[previous as usize].next;
                if nodes[candidate as usize].value == key {
                    nodes[previous as usize].next = nodes[candidate as usize].next;
                    if tail == candidate { tail = previous; }
                    deleted = true;
                    break;
                }
                previous = candidate;
            }
        }
        staged[word_count] = i64::from(deleted);
        word_count += 1;
        let mut remaining = 0_usize;
        let mut node = head;
        while node >= 0 { remaining += 1; node = nodes[node as usize].next; }
        staged[word_count] = remaining as i64;
        word_count += 1;
        let mut node = head;
        while node >= 0 {
            staged[word_count] = nodes[node as usize].value as i64;
            word_count += 1;
            node = nodes[node as usize].next;
        }
    }

    let output_bytes = word_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for index in 0..word_count {
        let bytes = staged[index].to_le_bytes();
        std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(index * 8), 8);
    }
    output_bytes as i64
}
