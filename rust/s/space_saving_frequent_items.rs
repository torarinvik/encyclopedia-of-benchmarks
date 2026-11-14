#[derive(Clone, Copy)]
struct Entry { item: i64, estimate: i64, error: i64 }

#[no_mangle]
pub unsafe extern "C" fn space_saving_frequent_items(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(2..=67).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if !(1..=8).contains(&values[0]) || !(0..=64).contains(&values[1]) { return -1; }
    let k = values[0] as usize;
    let n = values[1] as usize;
    if length != 2+n || values[2..].iter().any(|&x| !(-1000..=1000).contains(&x)) { return -1; }
    let mut entries = [Entry { item: 0, estimate: 0, error: 0 }; 8];
    let mut used = 0;
    for &item in &values[2..] {
        if let Some(entry) = entries[..used].iter_mut().find(|entry| entry.item == item) {
            entry.estimate += 1;
        } else if used < k {
            entries[used] = Entry { item, estimate: 1, error: 0 };
            used += 1;
        } else {
            let victim = (0..used).min_by_key(|&i| (entries[i].estimate, entries[i].item)).unwrap();
            let minimum = entries[victim].estimate;
            entries[victim] = Entry { item, estimate: minimum + 1, error: minimum };
        }
    }
    entries[..used].sort_unstable_by_key(|entry| entry.item);
    let bytes = 8*(1+3*used);
    if output.is_null() || capacity < bytes { return -2; }
    let mut staged = [0u8; 200];
    staged[..8].copy_from_slice(&(used as i64).to_le_bytes());
    for (i, entry) in entries[..used].iter().enumerate() {
        for (j, value) in [entry.item, entry.estimate, entry.error].iter().enumerate() {
            let offset = 8*(1+3*i+j);
            staged[offset..offset+8].copy_from_slice(&value.to_le_bytes());
        }
    }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, bytes);
    bytes as i64
}
