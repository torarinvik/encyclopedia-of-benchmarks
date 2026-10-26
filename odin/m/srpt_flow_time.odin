package srpt_flow_time
import "core:c"
put64 :: proc(o:[^]u8,p:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
srpt_flow_time :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<4||length>26 do return -1
 mr,nr:=input[0],input[1]
 if mr<1||mr>4||nr<1||nr>12||length!=c.size_t(2+2*nr) do return -1
 machines,n:=int(mr),int(nr);release,rem,completion:[12]i64
 for i:=0;i<n;i+=1{release[i]=input[2+2*i];rem[i]=input[3+2*i];if release[i]<0||release[i]>50||rem[i]<1||rem[i]>10 do return -1}
 bytes:=8*(1+n);if output==nil||capacity<c.size_t(bytes) do return -2
 time:i64=0;done:=0
 for done<n{
  chosen:[12]bool;selected:[12]int;count:=0
  for machine:=0;machine<machines;machine+=1{best:=n;for i:=0;i<n;i+=1{if !chosen[i]&&rem[i]>0&&release[i]<=time&&(best==n||rem[i]<rem[best]||(rem[i]==rem[best]&&i<best)){best=i}};if best==n do break;chosen[best]=true;selected[count]=best;count+=1}
  if count==0{next:=i64(51);for i:=0;i<n;i+=1{if rem[i]>0&&release[i]<next{next=release[i]}};time=next}else{time+=1;for j:=0;j<count;j+=1{i:=selected[j];rem[i]-=1;if rem[i]==0{completion[i]=time;done+=1}}}
 }
 total:i64=0;for i:=0;i<n;i+=1{total+=completion[i]-release[i]};put64(output,0,total);for i:=0;i<n;i+=1{put64(output,8*(1+i),completion[i])};return i64(bytes)
}
