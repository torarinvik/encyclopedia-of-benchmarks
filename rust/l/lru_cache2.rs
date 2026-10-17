use std::collections::{HashMap, HashSet};

const MAX_CAPACITY: usize = 64;
const MAX_OPERATIONS: usize = 256;
const MAX_INPUT_LENGTH: usize = 771;

#[derive(Clone, Copy, Default)]
struct CacheNode {
    key: i32,
    value: i32,
    previous: i32,
    next: i32,
}

fn unlink(nodes: &mut [CacheNode; MAX_CAPACITY], head: &mut i32, tail: &mut i32, node: usize) {
    let previous = nodes[node].previous;
    let next = nodes[node].next;
    if previous < 0 { *head = next; } else { nodes[previous as usize].next = next; }
    if next < 0 { *tail = previous; } else { nodes[next as usize].previous = previous; }
}

fn link_at_head(nodes: &mut [CacheNode; MAX_CAPACITY], head: &mut i32, tail: &mut i32, node: usize) {
    nodes[node].previous = -1;
    nodes[node].next = *head;
    if *head < 0 { *tail = node as i32; } else { nodes[*head as usize].previous = node as i32; }
    *head = node as i32;
}

fn promote(nodes: &mut [CacheNode; MAX_CAPACITY], head: &mut i32, tail: &mut i32, node: usize) {
    if *head == node as i32 { return; }
    unlink(nodes, head, tail, node);
    link_at_head(nodes, head, tail, node);
}

unsafe fn store_i64(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn lru_cache2(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if words[0] < 2 || words[0] > MAX_CAPACITY as i64 || words[1] < 0 || words[1] > MAX_OPERATIONS as i64 { return -1; }
    let cache_capacity = words[0] as usize;
    let operation_count = words[1] as usize;
    if length != 2 + operation_count * 3 { return -1; }

    let mut nodes = [CacheNode::default(); MAX_CAPACITY];
    let mut map = HashMap::<i32, usize>::with_capacity(cache_capacity);
    let mut seen_put_keys = HashSet::<i32>::with_capacity(operation_count);
    let mut head = -1_i32;
    let mut tail = -1_i32;
    let mut node_count = 0_usize;
    let mut results = [0_i64; MAX_OPERATIONS];

    for operation in 0..operation_count {
        let base = 2 + operation * 3;
        let opcode = words[base];
        let first = words[base + 1];
        let second = words[base + 2];
        if !(0..=4).contains(&opcode) { return -1; }
        if opcode == 0 {
            if first < i32::MIN as i64 || first > i32::MAX as i64 || second < i32::MIN as i64 || second > i32::MAX as i64 { return -1; }
            let key = first as i32;
            if !seen_put_keys.insert(key) { return -1; }
            let node: usize;
            if node_count < cache_capacity {
                node = node_count;
                node_count += 1;
            } else {
                node = tail as usize;
                map.remove(&nodes[node].key);
                unlink(&mut nodes, &mut head, &mut tail, node);
            }
            nodes[node].key = key;
            nodes[node].value = second as i32;
            if map.insert(key, node).is_some() { return -1; }
            link_at_head(&mut nodes, &mut head, &mut tail, node);
            results[operation] = i64::MIN;
        } else if opcode == 1 {
            if first < i32::MIN as i64 || first > i32::MAX as i64 || second != 0 { return -1; }
            let key = first as i32;
            let node = match map.get(&key) { Some(&node) => node, None => return -1 };
            promote(&mut nodes, &mut head, &mut tail, node);
            results[operation] = nodes[node].value as i64;
        } else {
            if first != 0 || second != 0 { return -1; }
            results[operation] = match opcode {
                2 => node_count as i64,
                3 => cache_capacity as i64,
                _ => if node_count == 0 { 1 } else { 0 },
            };
        }
    }

    let output_bytes = operation_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for operation in 0..operation_count { store_i64(output, operation * 8, results[operation]); }
    output_bytes as i64
}
