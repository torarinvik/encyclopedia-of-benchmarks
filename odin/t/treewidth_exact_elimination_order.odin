package treewidth_exact_elimination_order
import "core:c"

N :: 8
MAX_EDGES :: 28
MAX_INPUT :: 58
MAX_OUTPUT :: 72

put_i64 :: proc(out:[^]u8,offset:int,value:i64){bits:=u64(value);for byte:=0;byte<8;byte+=1{out[offset+byte]=u8(bits&255);bits>>=8}}

@(export)
treewidth_exact_elimination_order :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<2||length>MAX_INPUT||input[0]<1||input[0]>N||input[1]<0||input[1]>MAX_EDGES{return -1}
    n,m:=int(input[0]),int(input[1]);if m>n*(n-1)/2||length!=c.size_t(2+2*m){return -1}
    base:[N][N]bool
    for e:=0;e<m;e+=1{a0,b0:=input[2+2*e],input[3+2*e];if a0<0||b0<0||a0>=i64(n)||b0>=i64(n)||a0>=b0{return -1};a,b:=int(a0),int(b0);if base[a][b]{return -1};base[a][b]=true;base[b][a]=true}
    perm:[N]int;best_order:[N]int;for i:=0;i<n;i+=1{perm[i]=i};best_width:=N+1
    for { adjacent:=base;active:[N]bool;for i:=0;i<n;i+=1{active[i]=true};width:=0
        for step:=0;step<n;step+=1{vertex:=perm[step];neighbors:[N]int;count:=0;for other:=0;other<n;other+=1{if active[other]&&adjacent[vertex][other]{neighbors[count]=other;count+=1}};if count>width{width=count};for i:=0;i<count;i+=1{for j:=i+1;j<count;j+=1{a,b:=neighbors[i],neighbors[j];adjacent[a][b]=true;adjacent[b][a]=true}};active[vertex]=false}
        if width<best_width{best_width=width;for i:=0;i<n;i+=1{best_order[i]=perm[i]}}
        pivot:=n-2;for pivot>=0&&perm[pivot]>=perm[pivot+1]{pivot-=1};if pivot<0{break};successor:=n-1;for perm[successor]<=perm[pivot]{successor-=1};temp:=perm[pivot];perm[pivot]=perm[successor];perm[successor]=temp;left,right:=pivot+1,n-1;for left<right{temp=perm[left];perm[left]=perm[right];perm[right]=temp;left+=1;right-=1}
    }
    bytes:=8*(n+1);if output==nil||capacity<c.size_t(bytes){return -2};staged:[MAX_OUTPUT]u8;put_i64(&staged[0],0,i64(best_width));for i:=0;i<n;i+=1{put_i64(&staged[0],8*(i+1),i64(best_order[i]))};for i:=0;i<bytes;i+=1{output[i]=staged[i]};return i64(bytes)
}
