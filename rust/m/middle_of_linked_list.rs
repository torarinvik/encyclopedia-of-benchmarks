/// Return the second middle node's index in a successor-index list.
const MAX_NODES: usize = 100000;

#[no_mangle]
pub unsafe extern "C" fn middle_of_linked_list(next: *const i64, length: usize) -> i64 {
    if length > MAX_NODES || (length != 0 && next.is_null()) { return -2; }
    for index in 0..length {
        let successor = *next.add(index);
        if successor < -1 || successor >= length as i64 { return -2; }
    }
    if length == 0 { return -1; }

    let mut slow = 0i64;
    let mut fast = 0i64;
    while fast >= 0 {
        let first = *next.add(fast as usize);
        if first < 0 { break; }
        slow = *next.add(slow as usize);
        fast = *next.add(first as usize);
        if slow == fast { return -2; }
    }

    slow = 0;
    fast = 0;
    while fast >= 0 {
        let first = *next.add(fast as usize);
        if first < 0 { break; }
        slow = *next.add(slow as usize);
        fast = *next.add(first as usize);
    }
    slow
}
