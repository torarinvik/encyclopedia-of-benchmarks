@[export: 'srpt_flow_time']
pub fn srpt_flow_time(input &i64,length usize,mut output &u8,capacity usize)i64{
 unsafe{
  if input==nil||length<4||length>26{return -1};mr:=input[0];nr:=input[1]
  if mr<1||mr>4||nr<1||nr>12||length!=usize(2+2*nr){return -1}
  machines:=int(mr);n:=int(nr);mut release:=[12]i64{};mut rem:=[12]i64{};mut completion:=[12]i64{}
  for i in 0..n{release[i]=input[2+2*i];rem[i]=input[3+2*i];if release[i]<0||release[i]>50||rem[i]<1||rem[i]>10{return -1}}
  bytes:=8*(1+n);if output==nil||capacity<usize(bytes){return -2};mut time:=i64(0);mut done:=0
  for done<n{mut chosen:=[12]bool{};mut selected:=[12]int{};mut count:=0
   for _ in 0..machines{mut best:=n;for i in 0..n{if !chosen[i]&&rem[i]>0&&release[i]<=time&&(best==n||rem[i]<rem[best]||(rem[i]==rem[best]&&i<best)){best=i}}if best==n{break};chosen[best]=true;selected[count]=best;count++}
   if count==0{mut next:=i64(51);for i in 0..n{if rem[i]>0&&release[i]<next{next=release[i]}};time=next}else{time++;for j in 0..count{i:=selected[j];rem[i]--;if rem[i]==0{completion[i]=time;done++}}}
  }
  mut total:=i64(0);for i in 0..n{total+=completion[i]-release[i]};values:=[]i64{len:1+n,init:0};values[0]=total;for i in 0..n{values[i+1]=completion[i]};for i,x in values{bits:=u64(x);for b in 0..8{output[8*i+b]=u8((bits>>(8*b))&255)}};return i64(bytes)
 }
}
