package double_ended_selection_sort
import "core:c"
const MAX_INPUT=256
store_le :: proc(out:[^]u8,off:int,x:i64){bits:=u64(x);for b in 0..<8{out[off+b]=u8((bits>>(b*8))&255)}}
@(export)
double_ended_selection_sort :: proc "c" (v:[^]i64,n:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if (v==nil&&n>0)||n>257 do return -1;if n>MAX_INPUT do return -1;work,starts,ends,result:[MAX_INPUT]i64={};for i in 0..<int(n){work[i]=v[i]};count:=int(n);used:=0;end_count:=0;for count>1{min_i,max_i:=0,0;for i in 1..<count{if work[i]<work[min_i] do min_i=i;if work[i]>work[max_i] do max_i=i};min_v,max_v:=work[min_i],work[max_i];starts[used]=min_v;used+=1;ends[end_count]=max_v;end_count+=1;for i in min_i..<count-1{work[i]=work[i+1]};count-=1;max_pos:=0;for max_pos<count&&work[max_pos]!=max_v{max_pos+=1};if max_pos==count do return -1;for i in max_pos..<count-1{work[i]=work[i+1]};count-=1};out_n:=0;for i in 0..<used{result[out_n]=starts[i];out_n+=1};for i in 0..<count{result[out_n]=work[i];out_n+=1};i:=end_count;for i>0{i-=1;result[out_n]=ends[i];out_n+=1};bytes:=8*out_n;if output==nil||capacity<c.size_t(bytes) do return -2;for i in 0..<out_n{store_le(output,8*i,result[i])};return i64(bytes)}
