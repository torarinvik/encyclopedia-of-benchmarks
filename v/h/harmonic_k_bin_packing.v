@[export: 'harmonic_k_bin_packing']
pub fn harmonic_k_bin_packing(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
 if input==nil||length<3||length>34{return -1}k64:=input[0];n64:=input[1]
 if k64<3||k64>8||n64<1||n64>32||length!=usize(2+n64){return -1}k:=int(k64);n:=int(n64)
 for i in 0..n{if input[2+i]<1||input[2+i]>10000{return -1}}
 bytes:=8*(n+1);if output==nil||capacity<usize(bytes){return -2}
 mut current:=[]i64{len:k,init:-1};mut remaining:=[]i64{len:k,init:0};mut assignment:=[]i64{len:n,init:0};mut bins:=i64(0)
 for i in 0..n{size:=input[2+i];mut kind:=k-1
  for c in 0..k-1{if size*i64(c+2)>10000{kind=c;break}}
  if current[kind]<0||size>remaining[kind]{current[kind]=bins;bins++;remaining[kind]=10000}
  assignment[i]=current[kind];remaining[kind]-=size
 }
 values:=[]i64{len:n+1,init:0};values[0]=bins;for i in 0..n{values[i+1]=assignment[i]}
 for idx,value in values{bits:=u64(value);for b in 0..8{output[8*idx+b]=u8((bits>>(8*b))&255)}}return i64(bytes)
 }
}
