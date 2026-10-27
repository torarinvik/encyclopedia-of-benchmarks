const MAX_N:usize=32;const MAX_K:usize=8;const MAX_INPUT:usize=34;const CAPACITY:i64=10000;
unsafe fn store_i64_le(output:*mut u8,off:usize,value:i64){let bits=value as u64;for b in 0..8{*output.add(off+b)=(bits>>(8*b)) as u8;}}
#[no_mangle]
pub unsafe extern "C" fn harmonic_k_bin_packing(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<3||length>MAX_INPUT{return -1}let k64=*input;let n64=*input.add(1);
 if k64<3||k64>MAX_K as i64||n64<1||n64>MAX_N as i64||length!=2+n64 as usize{return -1}
 let k=k64 as usize;let n=n64 as usize;for i in 0..n{let s=*input.add(2+i);if !(1..=CAPACITY).contains(&s){return -1}}
 let bytes=8*(n+1);if output.is_null()||capacity<bytes{return -2}
 let mut current=[-1i64;MAX_K];let mut remaining=[0i64;MAX_K];let mut assignment=[0i64;MAX_N];let mut bins=0i64;
 for i in 0..n{let size=*input.add(2+i);let mut kind=k-1;for c in 0..k-1{if size*(c as i64+2)>CAPACITY{kind=c;break}}
  if current[kind]<0||size>remaining[kind]{current[kind]=bins;bins+=1;remaining[kind]=CAPACITY}assignment[i]=current[kind];remaining[kind]-=size;
 }
 store_i64_le(output,0,bins);for i in 0..n{store_i64_le(output,8*(i+1),assignment[i])}bytes as i64
}
