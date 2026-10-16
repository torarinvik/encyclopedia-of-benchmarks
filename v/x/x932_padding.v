module x932_padding
@[export: 'x932_padding']
pub fn x932_padding(values &i64, length usize, output &u8, capacity usize) i64 {
 if unsafe{values==nil}||length<1||length>257{return -1}; if unsafe{values[0]<1||values[0]>64}{return -1}
 block:=int(unsafe{values[0]});n:=int(length)-1
 for i in 1..int(length){if unsafe{values[i]<0||values[i]>255}{return -1}}
 pad:=block-(n%block);total:=n+pad
 if total>int(capacity)||unsafe{output==nil}{return -2}
 for i in 0..n{unsafe{output[i]=u8(values[i+1])}}
 for i in n..total-1{unsafe{output[i]=0}}
 unsafe{output[total-1]=u8(pad)};return i64(total)
}
