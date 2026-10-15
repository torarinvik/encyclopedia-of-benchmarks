fn store_i32_le(value: u32, output: &mut [u8], offset: usize) { output[offset..offset+4].copy_from_slice(&value.to_le_bytes()); }

#[no_mangle]
pub unsafe extern "C" fn matrix_addition(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 { return -2; }
    let a=std::slice::from_raw_parts(input,length);
    if !(0..=16).contains(&a[0]) || !(0..=16).contains(&a[1]) { return -2; }
    let (ra,ca)=(a[0] as usize,a[1] as usize); if ra==0&&ca!=0{return -2;}
    let na=ra*ca;let bd=2+na;if bd+2>length||!(0..=16).contains(&a[bd])||!(0..=16).contains(&a[bd+1]){return -2;}
    let (rb,cb)=(a[bd] as usize,a[bd+1] as usize);if rb==0&&cb!=0{return -2;}
    let nb=rb*cb;if length!=bd+2+nb{return -2;}if ra!=rb||ca!=cb{return -1;}
    for i in 0..na { if !(i32::MIN as i64..=i32::MAX as i64).contains(&a[2+i])||!(i32::MIN as i64..=i32::MAX as i64).contains(&a[bd+2+i]){return -2;} }
    if na == 0 { return 0; }
    if capacity<na*4||(na!=0&&output.is_null()){return -3;}
    let out=std::slice::from_raw_parts_mut(output,na*4);
    for i in 0..na { store_i32_le((a[2+i] as i32 as u32).wrapping_add(a[bd+2+i] as i32 as u32),out,i*4); }
    na as i64
}
