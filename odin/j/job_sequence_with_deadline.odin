package job_sequence_with_deadline
import "core:c"
@(export)
job_sequence_with_deadline :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>129 do return -1;count:=v[0];if count<0||count>64||n!=c.size_t(1+2*count) do return -1;d:[64]i64;r:[64]i64;order:[64]int;for i:=0;i<int(count);i+=1{d[i]=v[1+c.size_t(2*i)];r[i]=v[2+c.size_t(2*i)];if d[i]< -1||d[i]>64||r[i]< -1000000||r[i]>1000000 do return -1;order[i]=i};for i:=1;i<int(count);i+=1{key:=order[i];j:=i;for j>0&&r[order[j-1]]<r[key]{order[j]=order[j-1];j-=1};order[j]=key};kept:=i64(0);for i:=0;i<int(count);i+=1{if d[order[i]]>=i64(i+1){kept+=1}};return kept}
