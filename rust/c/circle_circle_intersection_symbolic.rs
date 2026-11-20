//! Independently authored draft; not compiled or run.
#[no_mangle]
pub unsafe extern "C" fn circle_circle_intersection_symbolic(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 6 { return -1; }
    let v=unsafe { std::slice::from_raw_parts(input,6) };
    if v.iter().any(|x| !(-1000..=1000).contains(x)) || v[2]<1 || v[5]<1 { return -1; }
    let dx=v[3]-v[0]; let dy=v[4]-v[1]; let d=dx*dx+dy*dy;
    let mut words=[0i64;7]; let mut count=1;
    if d==0 { words[0]=if v[2]==v[5] {3} else {0}; }
    else {
        let t=d+v[2]*v[2]-v[5]*v[5]; let h=4*v[2]*v[2]*d-t*t;
        if h>=0 {
            let den=2*d; count=7;
            words=[if h==0 {1} else {2},den*v[0]+dx*t,den*v[1]+dy*t,den,-dy,dx,h];
        }
    }
    let needed=8*count;
    if output.is_null() || capacity<needed { return -2; }
    let out=unsafe { std::slice::from_raw_parts_mut(output,needed) };
    for (i,word) in words[..count].iter().enumerate() {
        out[8*i..8*i+8].copy_from_slice(&word.to_le_bytes());
    }
    needed as i64
}
