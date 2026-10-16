fn next_node(node: i64, n: i64, cycle_target: i64) -> i64 {
    if node < 0 { return -1; }
    if node + 1 < n { node + 1 } else { cycle_target }
}

#[no_mangle]
pub unsafe extern "C" fn two_pointer_technique(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 4 || length > 132 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (op, n, cycle_target, k) = (values[0], values[1], values[2], values[3]);
    if !(0..=128).contains(&n) || length != 4 + n as usize { return -1; }
    if (n == 0 && cycle_target != -1) || (n > 0 && (cycle_target < -1 || cycle_target >= n)) { return -1; }
    if values[4..].iter().any(|&v| !(-1_000_000..=1_000_000).contains(&v)) { return -1; }

    if op == 0 {
        if k != 0 { return -1; }
        let mut slow = if n == 0 { -1 } else { 0 };
        let mut fast = slow;
        while fast != -1 {
            slow = next_node(slow, n, cycle_target);
            fast = next_node(fast, n, cycle_target);
            if fast != -1 { fast = next_node(fast, n, cycle_target); }
            if slow == -1 || fast == -1 { break; }
            if slow == fast { return 1; }
        }
        return 0;
    }
    if op == 1 {
        if cycle_target != -1 || k != 0 { return -1; }
        if n == 0 { return -2; }
        let (mut slow, mut fast) = (0, 0);
        while fast != -1 {
            fast = next_node(fast, n, cycle_target);
            if fast == -1 { break; }
            fast = next_node(fast, n, cycle_target);
            slow = next_node(slow, n, cycle_target);
        }
        return values[4 + slow as usize] + 1_000_001;
    }
    if op == 2 {
        if cycle_target != -1 || k < 1 || k > n { return -1; }
        let (mut lead, mut lag) = (0, 0);
        for _ in 0..k { lead = next_node(lead, n, cycle_target); }
        while lead != -1 {
            lead = next_node(lead, n, cycle_target);
            lag = next_node(lag, n, cycle_target);
        }
        return values[4 + lag as usize] + 3_000_002;
    }
    -1
}
