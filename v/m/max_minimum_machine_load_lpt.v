@[export: 'max_minimum_machine_load_lpt']
pub fn max_minimum_machine_load_lpt(input &i64,length usize,output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<3||length>18{return -1};nr:=input[0];mr:=input[1];if nr<1||nr>16||mr<1||mr>4||length!=usize(2+nr){return -1}
  n:=int(nr);m:=int(mr);mut p:=[]i64{len:n,init:0};mut order:=[]int{len:n,init:0};mut assign:=[]int{len:n,init:0};mut loads:=[]i64{len:m,init:0}
  for i in 0..n{p[i]=input[2+i];if p[i]<1||p[i]>100{return -1};order[i]=i};bytes:=8*(1+n+m);if output==nil||capacity<usize(bytes){return -2}
  for i in 1..n{key:=order[i];mut j:=i;for j>0{prev:=order[j-1];if p[key]>p[prev]||(p[key]==p[prev]&&key<prev){order[j]=order[j-1];j--}else{break}};order[j]=key}
  for i in 0..n{job:=order[i];mut machine:=0;for j in 1..m{if loads[j]<loads[machine]{machine=j}};assign[job]=machine;loads[machine]+=p[job]}
  mut low:=loads[0];for j in 1..m{if loads[j]<low{low=loads[j]}};values:=[]i64{len:1+n+m,init:0};values[0]=low;for i in 0..n{values[1+i]=i64(assign[i])};for j in 0..m{values[1+n+j]=loads[j]};for i,x in values{bits:=u64(x);for b in 0..8{output[8*i+b]=u8((bits>>(8*b))&255)}};return i64(bytes)
 }
}
