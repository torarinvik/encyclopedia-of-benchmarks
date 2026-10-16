package sum_of_subsets
import "core:c"
MAX_N :: 10
MAX_SOLUTIONS :: 1024
visit :: proc "contextless" (nums:[^]i64,n,start:int,target,current,remaining:i64,path:[^]i64,depth:int,solutions:[^]i64,lens:[^]int,count:^int) {
 if current>target||remaining+current<target do return
 if current==target { k:=count^;lens[k]=depth;for j:=0;j<depth;j+=1{solutions[k*MAX_N+j]=path[j]};count^+=1;return }
 for i:=start;i<n;i+=1{path[depth]=nums[i];visit(nums,n,i+1,target,current+nums[i],remaining-nums[i],path,depth+1,solutions,lens,count)}
}
put64 :: proc "contextless" (out:[^]u8,pos:^int,x:i64){v:=u64(x);for j:=0;j<8;j+=1{out[pos^]=u8(v&255);pos^+=1;v>>=8}}
@(export)
sum_of_subsets :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length<2 do return -1;n0:=input[0];target:=input[1];if n0<0||n0>10||length!=c.size_t(n0+2)||target<0||target>250 do return -1;n:=int(n0)
 nums:[MAX_N]i64;rem:=i64(0);for i:=0;i<n;i+=1{x:=input[2+i];if x<0||x>50 do return -1;nums[i]=x;rem+=x}
 path:[MAX_N]i64;solutions:[MAX_SOLUTIONS][MAX_N]i64;lens:[MAX_SOLUTIONS]int;count:=0;visit(&nums[0],n,0,target,0,rem,&path[0],0,&solutions[0][0],&lens[0],&count)
 need:=8;for i:=0;i<count;i+=1{need+=8+8*lens[i]};if output==nil||capacity<c.size_t(need) do return -2;pos:=0;put64(output,&pos,i64(count));for i:=0;i<count;i+=1{put64(output,&pos,i64(lens[i]));for j:=0;j<lens[i];j+=1{put64(output,&pos,solutions[i][j])}};return i64(pos)
}
