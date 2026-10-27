const MAX_STEPS: usize = 8;
const MAX_INPUT: usize = 18;
const MAX_OUTPUT: usize = 16;
const MAX_BID: i64 = 16;

#[no_mangle]
pub unsafe extern "C" fn single_parameter_truthful_payment(
    values: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if values.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let v = std::slice::from_raw_parts(values, length);
    if v[0] < 0 || v[0] > MAX_BID || v[1] < 1 || v[1] > MAX_STEPS as i64 { return -1; }
    let bid = v[0] as usize;
    let k = v[1] as usize;
    if length != 2 + 2*k { return -1; }
    for i in 0..k {
        let point = v[2+2*i];
        let load = v[3+2*i];
        if point < 0 || point >= MAX_BID || load < 0 || load > MAX_BID { return -1; }
        if (i == 0 && point != 0) || (i > 0 && (point <= v[2+2*(i-1)] || load > v[3+2*(i-1)])) { return -1; }
    }
    let mut allocation = 0i64;
    if bid < MAX_BID as usize {
        for i in 0..k { if v[2+2*i] as usize <= bid { allocation = v[3+2*i]; } }
    }
    let mut area = 0i64;
    for i in 0..k {
        let start = v[2+2*i] as usize;
        let end = if i+1 < k { v[2+2*(i+1)] as usize } else { MAX_BID as usize };
        let left = start.max(bid);
        if end > left { area += ((end-left) as i64) * v[3+2*i]; }
    }
    let payment = (bid as i64) * allocation + area;
    if output.is_null() || capacity < MAX_OUTPUT { return -2; }
    let mut staged = [0u8; MAX_OUTPUT];
    staged[..8].copy_from_slice(&allocation.to_le_bytes());
    staged[8..].copy_from_slice(&payment.to_le_bytes());
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, MAX_OUTPUT);
    MAX_OUTPUT as i64
}
