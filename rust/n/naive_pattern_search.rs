#[no_mangle]
pub extern "C" fn naive_pattern_search(v: *const i64, n: usize) -> i64 {
    if v.is_null() || n < 2 || n > 512 { return -2; }
    let tn=unsafe{*v}; let pn=unsafe{*v.add(1)};
    if tn < 0 || tn > 255 || pn < 0 || pn > tn || n != (2+tn+pn) as usize { return -2; }
    for i in 0..(tn+pn) as usize { let b=unsafe{*v.add(2+i)}; if !(0..=127).contains(&b) { return -2; } }
    if pn == 0 { return -1; }
    for start in 0..=(tn-pn) {
        let mut j=0;
        while j<pn && unsafe{*v.add((2+start+j) as usize)}==unsafe{*v.add((2+tn+j) as usize)} { j+=1; }
        if j==pn { return start; }
    }
    -1
}
