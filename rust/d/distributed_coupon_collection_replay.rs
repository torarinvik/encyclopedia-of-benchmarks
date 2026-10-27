const MAX_N: usize = 8;
const MAX_INPUT: usize = 76;

unsafe fn put64(output: *mut u8, offset: usize, value: i64) {
    let bits=value as u64;
    for byte in 0..8 { *output.add(offset+byte)=(bits>>(8*byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn distributed_coupon_collection_replay(input:*const i64,length:usize,
    output:*mut u8,capacity:usize)->i64 {
    if input.is_null()||length<4||length>MAX_INPUT{return -1;}
    let n64=*input;let c64=*input.add(1);let copies=*input.add(2);let steps64=*input.add(3);
    if n64<2||n64>8||c64<1||c64>8||copies<1||copies>n64||steps64<1||steps64>8||length!=4+n64 as usize+n64 as usize*steps64 as usize{return -1;}
    let n=n64 as usize;let coupons=c64 as usize;let steps=steps64 as usize;let full=(1_u64<<coupons)-1;
    let mut bins=[0_u64;MAX_N];
    for b in 0..n{let raw=*input.add(4+b);if raw<0||(raw as u64)&!full!=0{return -1;}bins[b]=raw as u64;}
    for coupon in 0..coupons{let mut count=0;for b in 0..n{if (bins[b]>>coupon)&1!=0{count+=1;}}if count<copies as usize{return -1;}}
    let tape_at=4+n;for i in 0..n*steps{let bit=*input.add(tape_at+i);if bit!=0&&bit!=1{return -1;}}
    if output.is_null()||capacity<16{return -2;}
    let mut collected=0_u64;let mut singleton_steps=0_i64;
    for step in 0..steps{let mut open_count=0;let mut opened_bin=0;for bin in 0..n{if *input.add(tape_at+step*n+bin)==1{open_count+=1;opened_bin=bin;}}if open_count==1{singleton_steps+=1;collected|=bins[opened_bin];}}
    let mut staged=[0_u8;16];put64(staged.as_mut_ptr(),0,collected as i64);put64(staged.as_mut_ptr(),8,singleton_steps);for byte in 0..16{*output.add(byte)=staged[byte];}16
}
