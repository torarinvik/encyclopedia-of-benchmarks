const MAX_NODES: usize = 128;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_OUTPUT_BYTES: usize = 12 * MAX_NODES;

#[derive(Clone, Copy)]
struct ListNode { value: i32, next: i32, origin: i32, position: i32 }

fn put_i32_le(output: &mut [u8], offset: usize, value: i32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn merge_sorted_singly_linked_list(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if !(0..=MAX_NODES as i64).contains(&words[0]) { return -1; }
    let len_a = words[0] as usize;
    if len_a > length - 2 { return -1; }
    let len_b_pos = 1 + len_a;
    let raw_len_b = words[len_b_pos];
    if raw_len_b < 0 || raw_len_b > (MAX_NODES - len_a) as i64 { return -1; }
    let len_b = raw_len_b as usize;
    let total = len_a + len_b;
    if length != 2 + total { return -1; }

    let mut nodes = [ListNode { value: 0, next: -1, origin: 0, position: 0 }; MAX_NODES];
    for i in 0..len_a {
        let raw = words[1 + i];
        if raw < i32::MIN as i64 || raw > i32::MAX as i64 || (i > 0 && words[i] > raw) { return -1; }
        nodes[i] = ListNode { value: raw as i32, next: if i + 1 < len_a { (i + 1) as i32 } else { -1 }, origin: 0, position: i as i32 };
    }
    let b_start = len_b_pos + 1;
    for i in 0..len_b {
        let raw = words[b_start + i];
        if raw < i32::MIN as i64 || raw > i32::MAX as i64 || (i > 0 && words[b_start + i - 1] > raw) { return -1; }
        let node = len_a + i;
        nodes[node] = ListNode { value: raw as i32, next: if i + 1 < len_b { (node + 1) as i32 } else { -1 }, origin: 1, position: i as i32 };
    }

    let mut head_a = if len_a == 0 { -1 } else { 0 };
    let mut head_b = if len_b == 0 { -1 } else { len_a as i32 };
    let mut merged_head = -1;
    let mut tail = -1;
    while head_a >= 0 && head_b >= 0 {
        let node;
        if nodes[head_a as usize].value <= nodes[head_b as usize].value {
            node = head_a;
            head_a = nodes[node as usize].next;
        } else {
            node = head_b;
            head_b = nodes[node as usize].next;
        }
        if tail < 0 { merged_head = node; } else { nodes[tail as usize].next = node; }
        tail = node;
    }
    let remainder = if head_a >= 0 { head_a } else { head_b };
    if tail < 0 { merged_head = remainder; } else { nodes[tail as usize].next = remainder; }

    let bytes = 12 * total;
    if output.is_null() || capacity < bytes { return -2; }
    let mut buffer = [0u8; MAX_OUTPUT_BYTES];
    let mut written = 0usize;
    let mut node = merged_head;
    while node >= 0 {
        let item = nodes[node as usize];
        put_i32_le(&mut buffer, written, item.value);
        put_i32_le(&mut buffer, written + 4, item.origin);
        put_i32_le(&mut buffer, written + 8, item.position);
        written += 12;
        node = item.next;
    }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, bytes);
    bytes as i64
}
