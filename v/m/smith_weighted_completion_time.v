@[export: 'smith_weighted_completion_time']
pub fn smith_weighted_completion_time(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<3||length>25{return -1}
  n64:=input[0];if n64<1||n64>12||length!=usize(1+2*n64){return -1};n:=int(n64)
  mut p:=[]i64{len:n,init:0};mut w:=[]i64{len:n,init:0};mut order:=[]int{len:n,init:0}
  for i in 0..n{p[i]=input[1+2*i];w[i]=input[2+2*i];if p[i]<1||p[i]>10000||w[i]<1||w[i]>10000{return -1};order[i]=i}
  bytes:=8*(n+1);if output==nil||capacity<usize(bytes){return -2}
  for i in 1..n{key:=order[i];mut j:=i;for j>0{prev:=order[j-1];before:=w[key]*p[prev]>w[prev]*p[key]||(w[key]*p[prev]==w[prev]*p[key]&&key<prev);if !before{break};order[j]=order[j-1];j--};order[j]=key}
  mut elapsed:=i64(0);mut total:=i64(0);for i in 0..n{job:=order[i];elapsed+=p[job];total+=w[job]*elapsed}
  values:=[]i64{len:n+1,init:0};values[0]=total;for i in 0..n{values[i+1]=i64(order[i])}
  for index,value in values{bits:=u64(value);for b in 0..8{output[8*index+b]=u8((bits>>(8*b))&255)}};return i64(bytes)
 }
}
