const MAX_N: usize = 16;
const MAX_INPUT: usize = 17;
const SAMPLE: [usize; 17] = [0,0,0,1,1,1,2,2,2,3,3,4,4,4,5,5,5];

unsafe fn put64(out:*mut u8,value:i64){let bits=value as u64;for j in 0..8{*out.add(j)=(bits>>(8*j)) as u8;}}

#[no_mangle]
pub unsafe extern "C" fn secretary_1e_threshold(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
    if input.is_null()||length<4||length>MAX_INPUT{return -1;}
    let n64=*input;if n64<3||n64>MAX_N as i64||length!=n64 as usize+1{return -1;}let n=n64 as usize;
    let mut seen=[false;MAX_N+1];
    for i in 0..n{let rank=*input.add(i+1);if rank<1||rank>n64||seen[rank as usize]{return -1;}seen[rank as usize]=true;}
    let observed=SAMPLE[n];let mut threshold=*input.add(1);
    for i in 1..observed{let rank=*input.add(1+i);if rank>threshold{threshold=rank;}}
    let mut selected=-1i64;for i in observed..n{if *input.add(1+i)>threshold{selected=i as i64;break;}}
    if output.is_null()||capacity<8{return -2;}let mut staged=[0u8;8];put64(staged.as_mut_ptr(),selected);for i in 0..8{*output.add(i)=staged[i];}8
}
