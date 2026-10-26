@[export: 'min_hash_k_mins']
pub fn min_hash_k_mins(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{if input==nil||length<3||length>66{return -1};nr:=input[0];kr:=input[1];if nr<1||nr>16||kr<1||kr>4||length!=usize(2+nr*kr){return -1};n:=int(nr);k:=int(kr);for i in 0..(n*k){if input[2+i]<0||input[2+i]>1000{return -1}};bytes:=8*k;if output==nil||capacity<usize(bytes){return -2};for col in 0..k{mut best:=0;for row in 1..n{if input[2+row*k+col]<input[2+best*k+col]{best=row}};bits:=u64(best);for b in 0..8{output[8*col+b]=u8((bits>>(8*b))&255)}};return i64(bytes)}
}
