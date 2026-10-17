use std::collections::HashMap;

const MAX_ITEMS: usize = 64;
const MAX_OPS: usize = 256;
const NIL: i64 = i64::MIN;

#[derive(Clone, Copy)]
struct Entry { priority: i32, index: usize }

fn swap(heap: &mut [i32; MAX_ITEMS], map: &mut HashMap<i32, Entry>, a: usize, b: usize, update_indices: bool) {
    heap.swap(a, b);
    if update_indices {
        map.get_mut(&heap[a]).unwrap().index = a;
        map.get_mut(&heap[b]).unwrap().index = b;
    }
}
fn down(heap: &mut [i32; MAX_ITEMS], count: usize, map: &mut HashMap<i32, Entry>, mut index: usize, update_indices: bool) {
    loop {
        let left = index * 2 + 1;
        if left >= count { return; }
        let mut child = left + 1;
        if child >= count || map[&heap[left]].priority < map[&heap[child]].priority { child = left; }
        if map[&heap[child]].priority >= map[&heap[index]].priority { return; }
        swap(heap, map, index, child, update_indices); index = child;
    }
}
fn up(heap: &mut [i32; MAX_ITEMS], map: &mut HashMap<i32, Entry>, mut index: usize) {
    while index > 0 {
        let parent = (index - 1) / 2;
        if map[&heap[index]].priority >= map[&heap[parent]].priority { return; }
        swap(heap, map, index, parent, true); index = parent;
    }
}

#[no_mangle]
pub unsafe extern "C" fn table_heap(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 1155 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_ITEMS as i64 { return -1; }
    let initial = values[0] as usize; let op_index = 1 + 2 * initial;
    if length <= op_index || values[op_index] < 0 || values[op_index] > MAX_OPS as i64 { return -1; }
    let op_count = values[op_index] as usize;
    if length != 2 + 2 * initial + 4 * op_count || length > 1154 { return -1; }

    let mut heap = [0i32; MAX_ITEMS]; let mut map = HashMap::<i32, Entry>::with_capacity(MAX_ITEMS);
    for i in 0..initial {
        let id = values[1 + 2 * i]; let p = values[2 + 2 * i];
        if id < i32::MIN as i64 || id > i32::MAX as i64 || p < i32::MIN as i64 || p > i32::MAX as i64 { return -1; }
        let id = id as i32;
        if map.contains_key(&id) { return -1; }
        heap[i] = id; map.insert(id, Entry { priority: p as i32, index: 0 });
    }
    let mut count = initial;
    for parent in (0..count / 2).rev() { down(&mut heap, count, &mut map, parent, false); }
    for i in 0..count { map.get_mut(&heap[i]).unwrap().index = i; }

    let mut answers = [0i64; MAX_OPS]; let mut cursor = op_index + 1;
    for oi in 0..op_count {
        let op = values[cursor]; let a = values[cursor + 1]; let b = values[cursor + 2]; let c = values[cursor + 3]; cursor += 4;
        if !(0..=9).contains(&op) { return -1; }
        if op == 0 {
            if a < i32::MIN as i64 || a > i32::MAX as i64 || b < i32::MIN as i64 || b > i32::MAX as i64 || c != 0 || count == MAX_ITEMS { return -1; }
            let id = a as i32; if map.contains_key(&id) { return -1; }
            heap[count] = id; map.insert(id, Entry { priority: b as i32, index: count }); count += 1;
            up(&mut heap, &mut map, count - 1); answers[oi] = NIL;
        } else if op == 1 {
            if a != 0 || b != 0 || c != 0 { return -1; }
            answers[oi] = if count == 0 { NIL } else { heap[0] as i64 };
        } else if op == 2 {
            if a != 0 || b != 0 || c != 0 || count == 0 { return -1; }
            let removed = heap[0]; answers[oi] = removed as i64;
            swap(&mut heap, &mut map, 0, count - 1, true); count -= 1; map.remove(&removed);
            if count > 0 { down(&mut heap, count, &mut map, 0, true); }
        } else if op == 3 || op == 4 {
            if a != 0 || b != 0 || c != 0 { return -1; }
            answers[oi] = if op == 3 { count as i64 } else if count == 0 { 1 } else { 0 };
        } else if op == 5 {
            if a < i32::MIN as i64 || a > i32::MAX as i64 || b != 0 || c != 0 { return -1; }
            answers[oi] = map.get(&(a as i32)).map_or(NIL, |entry| (entry.index + 1) as i64);
        } else if op == 6 || op == 7 {
            if a < i32::MIN as i64 || a > i32::MAX as i64 || b < i32::MIN as i64 || b > i32::MAX as i64 || c != 0 { return -1; }
            let id = a as i32; let old = match map.get(&id) { Some(entry) => entry.priority, None => return -1 };
            if (op == 6 && b > old as i64) || (op == 7 && b < old as i64) { return -1; }
            let position = map[&id].index; map.get_mut(&id).unwrap().priority = b as i32;
            if op == 6 { up(&mut heap, &mut map, position); } else { down(&mut heap, count, &mut map, position, true); }
            answers[oi] = NIL;
        } else if op == 8 {
            if a < i32::MIN as i64 || a > i32::MAX as i64 || b < i32::MIN as i64 || b > i32::MAX as i64 || c < i32::MIN as i64 || c > i32::MAX as i64 { return -1; }
            let old_id = a as i32; let new_id = b as i32;
            let (position, old_priority) = match map.get(&old_id) { Some(entry) => (entry.index, entry.priority), None => return -1 };
            if map.contains_key(&new_id) {
                if new_id != old_id || c != old_priority as i64 { return -1; }
            } else {
                map.remove(&old_id); heap[position] = new_id;
                map.insert(new_id, Entry { priority: c as i32, index: position });
                if (c as i32) < old_priority { up(&mut heap, &mut map, position); } else { down(&mut heap, count, &mut map, position, true); }
            }
            answers[oi] = NIL;
        } else {
            if a < i32::MIN as i64 || a > i32::MAX as i64 || b != 0 || c != 0 { return -1; }
            let id = a as i32; let (position, old_priority) = match map.get(&id) { Some(entry) => (entry.index, entry.priority), None => return -1 };
            count -= 1;
            if position != count {
                heap[position] = heap[count]; map.get_mut(&heap[position]).unwrap().index = position;
                if map[&heap[position]].priority < old_priority { up(&mut heap, &mut map, position); } else { down(&mut heap, count, &mut map, position, true); }
            }
            map.remove(&id); answers[oi] = NIL;
        }
    }
    let output_bytes = op_count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for i in 0..op_count {
        let bits = answers[i] as u64;
        for byte in 0..8 { *output.add(i * 8 + byte) = (bits >> (8 * byte)) as u8; }
    }
    output_bytes as i64
}
