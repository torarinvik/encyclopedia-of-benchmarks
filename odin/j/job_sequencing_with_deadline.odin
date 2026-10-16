package job_sequencing_with_deadline
import "core:c"
@(export)
job_sequencing_with_deadline :: proc "c" (v:[^]i64,n:c.size_t)->i64{if v==nil||n<1||n>65 do return -1;count:=v[0];if count<1||count>32||n!=c.size_t(1+2*count) do return -1;d:[32]i64;p:[32]i64;order:[32]int;for i:=0;i<int(count);i+=1{d[i]=v[1+c.size_t(2*i)];p[i]=v[2+c.size_t(2*i)];if d[i]<0||d[i]>32||p[i]<0||p[i]>1000000 do return -1;order[i]=i};for i:=1;i<int(count);i+=1{key:=order[i];j:=i;for j>0&&p[order[j-1]]<p[key]{order[j]=order[j-1];j-=1};order[j]=key};slots:[33]bool;chosen:=i64(0);profit:=i64(0);for k:=0;k<int(count);k+=1{for s:=int(d[order[k]]);s>0;s-=1{if !slots[s]{slots[s]=true;chosen+=1;profit+=p[order[k]];break}}};return chosen*32000001+profit}
