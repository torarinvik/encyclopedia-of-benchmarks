package stack_tracking_min_max
import "core:c"
put64 :: proc "contextless" (output:[^]u8,pos:^int,value:i64){bits:=u64(value);for i:=0;i<8;i+=1{output[pos^]=u8(bits&255);pos^+=1;bits>>=8}}
@(export)
stack_tracking_min_max :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {if input==nil||length<2||length>130 do return -1;max_size,count:=input[0],input[1];if max_size<0||max_size>64||count<0||count>64 do return -1;p:=c.size_t(2);for i:=i64(0);i<count;i+=1{if p>=length do return -1;op:=input[p];p+=1;if op==1{if p>=length||input[p]<(-2147483647-1)||input[p]>2147483647 do return -1;p+=1}else if op<2||op>5 do return -1};if p!=length do return -1
 vals:[64]i64;mins:[64]i64;maxs:[64]i64;records:[64][3]i64;top:=0;rc:=0;p=2
 for i:=i64(0);i<count;i+=1{op:=input[p];p+=1;tag:=i64(0);result:=i64(0);if op==1{x:=input[p];p+=1;if top==int(max_size){records[rc]=[3]i64{1,4,1};rc+=1;break};vals[top]=x;mins[top]=x;maxs[top]=x;if top>0{if mins[top-1]<x{mins[top]=mins[top-1]};if maxs[top-1]>x{maxs[top]=maxs[top-1]}};top+=1;tag=1;result=1}else if op==2{if top>0{top-=1;result=vals[top]}else{tag=3}}else if op==3{if top>0{result=mins[top-1]}else{tag=3}}else if op==4{if top>0{result=maxs[top-1]}else{tag=3}}else{tag=1;if top>0{result=1}};records[rc]=[3]i64{op,tag,result};rc+=1}
 need:=c.size_t(rc*24);if output==nil||capacity<need do return -2;pos:=0;for i:=0;i<rc;i+=1{for j:=0;j<3;j+=1{put64(output,&pos,records[i][j])}};return i64(pos)}
