const MAX_BUCKETS: usize = 8;
const MAX_OPS: usize = 64;
const MAX_BYTES: usize = 520;

#[derive(Clone, Copy, Default)]
struct Item { key: u8, insertion: u8 }
fn before(a: Item, b: Item) -> bool { (a.key, a.insertion) < (b.key, b.insertion) }
fn push(heaps: &mut [[Item; MAX_OPS]; MAX_BUCKETS], sizes: &mut [usize; MAX_BUCKETS], bucket: usize, item: Item) {
    let mut child = sizes[bucket]; sizes[bucket] += 1; heaps[bucket][child] = item;
    while child > 0 {
        let parent = (child - 1) / 2;
        if !before(heaps[bucket][child], heaps[bucket][parent]) { break; }
        heaps[bucket].swap(child, parent); child = parent;
    }
}
fn pop(heaps: &mut [[Item; MAX_OPS]; MAX_BUCKETS], sizes: &mut [usize; MAX_BUCKETS], bucket: usize) {
    sizes[bucket] -= 1; let last = sizes[bucket];
    if last == 0 { return; }
    heaps[bucket][0] = heaps[bucket][last];
    let mut parent = 0;
    loop {
        let left = parent * 2 + 1; if left >= sizes[bucket] { break; }
        let mut child = left; let right = left + 1;
        if right < sizes[bucket] && before(heaps[bucket][right], heaps[bucket][left]) { child = right; }
        if !before(heaps[bucket][child], heaps[bucket][parent]) { break; }
        heaps[bucket].swap(child, parent); parent = child;
    }
}
fn put_word(out: &mut [u8; MAX_BYTES], at: usize, value: i64) {
    let bytes = value.to_le_bytes(); out[at..at + 8].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn hash_heap_priority_queue_trace(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 132 { return -1; }
    let values = unsafe { core::slice::from_raw_parts(input, length) };
    let (u, b, qv) = (values[0], values[1], values[2]);
    if !(1..=128).contains(&u) || !(1..=8).contains(&b) || b > u || !(0..=64).contains(&qv) { return -1; }
    let (universe, bucket_count, q) = (u as usize, b as usize, qv as usize);
    if length != 3 + 2 * q { return -1; }
    let mut ops = [0u8; MAX_OPS]; let mut args = [0u8; MAX_OPS];
    for i in 0..q {
        let (op, arg) = (values[3 + 2 * i], values[4 + 2 * i]);
        if op == 0 { if arg < 0 || arg as usize >= universe { return -1; } }
        else if op == 1 || op == 2 { if arg != 0 { return -1; } }
        else { return -1; }
        ops[i] = op as u8; args[i] = arg as u8;
    }
    let mut heaps = [[Item::default(); MAX_OPS]; MAX_BUCKETS];
    let mut sizes = [0usize; MAX_BUCKETS]; let mut staged = [0u8; MAX_BYTES];
    put_word(&mut staged, 0, q as i64);
    for i in 0..q {
        let at = (i + 1) * 8;
        if ops[i] == 0 {
            let bucket = args[i] as usize * bucket_count / universe;
            push(&mut heaps, &mut sizes, bucket, Item { key: args[i], insertion: i as u8 });
            put_word(&mut staged, at, -2); continue;
        }
        let mut bucket = 0; while bucket < bucket_count && sizes[bucket] == 0 { bucket += 1; }
        if bucket == bucket_count { put_word(&mut staged, at, -1); continue; }
        let item = heaps[bucket][0];
        put_word(&mut staged, at, ((item.insertion as i64) << 8) | item.key as i64);
        if ops[i] == 2 { pop(&mut heaps, &mut sizes, bucket); }
    }
    let required = (q + 1) * 8;
    if output.is_null() || capacity < required { return -2; }
    unsafe { core::ptr::copy_nonoverlapping(staged.as_ptr(), output, required); }
    required as i64
}
