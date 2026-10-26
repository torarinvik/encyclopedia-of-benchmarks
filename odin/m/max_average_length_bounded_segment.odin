package max_average_length_bounded_segment
import "core:c"
MAX_N::32;MAX_INPUT::35
put64::proc(o:[^]u8,p:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
max_average_length_bounded_segment::proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<4||length>MAX_INPUT do return -1
 n64,lower64,upper64:=input[0],input[1],input[2]
 if n64<1||n64>MAX_N||lower64<1||upper64<lower64||upper64>n64||length!=c.size_t(3+n64) do return -1
 n,lower,upper:=int(n64),int(lower64),int(upper64)
 for i:=0;i<n;i+=1{if input[3+i]<-10000||input[3+i]>10000 do return -1}
 if output==nil||capacity<32 do return -2
 best_sum:i64=0;best_len,best_start,best_end:=1,0,0;have:=false
 for start:=0;start<n;start+=1{
  sum:i64=0;limit:=start+upper;if limit>n{limit=n}
  for end:=start+1;end<=limit;end+=1{
   sum+=input[3+end-1];size:=end-start;if size<lower do continue
   left:=sum*i64(best_len);right:=best_sum*i64(size)
   tie:=size<best_len||(size==best_len&&(start<best_start||(start==best_start&&end<best_end)))
   if !have||left>right||(left==right&&tie){best_sum,best_len,best_start,best_end,have=sum,size,start,end,true}
  }
 }
 put64(output,0,best_sum);put64(output,8,i64(best_len));put64(output,16,i64(best_start));put64(output,24,i64(best_end));return 32
}
