#[no_mangle]
pub unsafe extern "C" fn three_way_partition(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 258 { return -1; }
    let n=*input; let pivot=*input.add(1);
    if !(0..=256).contains(&n)||length!=n as usize+2||pivot<i32::MIN as i64||pivot>i32::MAX as i64{return -1;}
    let mut a=Vec::with_capacity(n as usize); for i in 0..n as usize {let x=*input.add(i+2);if x<i32::MIN as i64||x>i32::MAX as i64{return -1;}a.push(x as i32);}
    let (mut low,mut mid,mut high)=(0usize,0usize,n as usize);while mid<high{if a[mid] as i64<pivot{a.swap(low,mid);low+=1;mid+=1;}else if a[mid] as i64>pivot{high-=1;a.swap(mid,high);}else{mid+=1;}}
    let bytes=(n as usize+2)*4;if capacity<bytes||output.is_null(){return -2;}for(i,x)in a.iter().enumerate(){std::ptr::copy_nonoverlapping(x.to_le_bytes().as_ptr(),output.add(4*i),4);}for (j,x) in [low as i32,high as i32].iter().enumerate(){std::ptr::copy_nonoverlapping(x.to_le_bytes().as_ptr(),output.add(4*(n as usize+j)),4);}n+2
}
