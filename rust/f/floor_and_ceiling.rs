fn put_i64_le(out: &mut [u8], offset: usize, value: i64) { out[offset..offset+8].copy_from_slice(&value.to_le_bytes()); }
#[no_mangle]
pub unsafe extern "C" fn floor_and_ceiling(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 3 || length > 384 { return -1; }
    let v = std::slice::from_raw_parts(input, length);
    let (raw_n, root, key) = (v[0], v[1], v[2]);
    if !(0..=127).contains(&raw_n) || !(-1_000_000..=1_000_000).contains(&key) || length != 3 + 3*raw_n as usize { return -1; }
    let n=raw_n as usize;
    if (n==0 && root!=-1) || (n!=0 && (root<0 || root>=raw_n)) { return -1; }
    let (mut floor,mut ceiling)=(i64::MIN,i64::MIN);
    let mut current=if n==0 {n} else {root as usize};
    for _ in 0..n {
        if current>=n {break;}
        let base=3+3*current; let (value,left,right)=(v[base],v[base+1],v[base+2]);
        if !(-1_000_000..=1_000_000).contains(&value) || left < -1 || right < -1 || left>=raw_n || right>=raw_n {return -1;}
        if value==key {floor=value;ceiling=value;break;}
        if key<value {ceiling=value;current=if left<0 {n} else {left as usize};}
        else {floor=value;current=if right<0 {n} else {right as usize};}
    }
    if output.is_null() || capacity<16 { return -2; }
    let out=std::slice::from_raw_parts_mut(output,16); put_i64_le(out,0,floor);put_i64_le(out,8,ceiling);16
}
