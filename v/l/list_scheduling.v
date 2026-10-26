@[export: 'list_scheduling']
pub fn list_scheduling(input &i64, length usize, output &u8, capacity usize) i64 {
 unsafe {
  if input==nil||length<3||length>34{return -1}
  m64,n64:=input[0],input[1]
  if m64<1||m64>8||n64<1||n64>32||length!=usize(2+n64){return -1}
  m,n:=int(m64),int(n64)
  for i in 0..n{if input[2+i]<1||input[2+i]>10000{return -1}}
  bytes:=8*(1+n+m);if output==nil||capacity<usize(bytes){return -2}
  mut load:=[]i64{len:m,init:0};mut assignment:=[]i64{len:n,init:0}
  for i in 0..n{mut best:=0;for j in 1..m{if load[j]<load[best]{best=j}};assignment[i]=i64(best);load[best]+=input[2+i]}
  mut span:=load[0];for j in 1..m{if load[j]>span{span=load[j]}}
  values:=[]i64{len:1+n+m,init:0};values[0]=span
  for i in 0..n{values[1+i]=assignment[i]};for j in 0..m{values[1+n+j]=load[j]}
  for index,value in values{bits:=u64(value);for b in 0..8{output[8*index+b]=u8((bits>>(8*b))&255)}}
  return i64(bytes)
 }
}
