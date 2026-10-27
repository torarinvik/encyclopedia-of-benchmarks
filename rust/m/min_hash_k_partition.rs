const K:usize=8;const N:usize=32;const EMPTY:i64=1001;
unsafe fn put(out:*mut u8,pos:usize,x:i64){for b in 0..8{*out.add(pos+b)=(x as u64>>(8*b)) as u8;}}
#[no_mangle] pub unsafe extern "C" fn min_hash_k_partition(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<2||length>66{return -1;}let k=*input;let n=*input.add(1);
 if !(1..=K as i64).contains(&k)||n<0||n>N as i64||length!=2+2*n as usize{return -1;}
 let mut ids=[-1i64;K];let mut ranks=[EMPTY;K];
 for id in 0..n as usize{let b=*input.add(2+2*id);let r=*input.add(3+2*id);if b<0||b>=k||r<0||r>1000{return -1;}let b=b as usize;if ids[b]<0||r<ranks[b]||(r==ranks[b]&&(id as i64)<ids[b]){ids[b]=id as i64;ranks[b]=r;}}
 let mut staged=[0i64;2*K];for b in 0..k as usize{staged[2*b]=ids[b];staged[2*b+1]=ranks[b];}
 let required=2*k as usize*8;if output.is_null()||capacity<required{return -2;}for i in 0..2*k as usize{put(output,i*8,staged[i]);}required as i64
}
