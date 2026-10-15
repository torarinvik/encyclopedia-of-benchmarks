fn pack(n: i32, d: i32) -> i64 { (((n as u32 as u64) << 32) | d as u32 as u64) as i64 }
#[no_mangle]
pub unsafe extern "C" fn adtfraction(raw: *const i64, length: usize) -> i64 {
    if raw.is_null() || length != 5 { return -1; }
    let a = std::slice::from_raw_parts(raw, length);
    if a.iter().any(|x| *x < -100000 || *x > 100000) || !(0..=4).contains(&a[0]) { return -1; }
    let (op,n,d,m,e)=(a[0] as i32,a[1] as i32,a[2] as i32,a[3] as i32,a[4] as i32);
    match op {
        0 => { if d==0||e==0{return -1;} let den=d.wrapping_mul(e); if den==0{-1}else{pack(d.wrapping_mul(m).wrapping_add(n.wrapping_mul(e)),den)} },
        1 => if d==0{-1}else{pack(n.wrapping_mul(m),d)},
        2 => { if d==0||e==0{return -1;} let den=d.wrapping_mul(e); if den==0{-1}else{pack(n.wrapping_mul(m),den)} },
        3 => if n==0{-1}else{pack(d,n)},
        _ => { if d==0{return -1;} ((n as f32 / d as f32).to_bits()) as i64 }
    }
}
