package kkt_mst_sampling_filter
import "core:c"

MAX_N :: 12
MAX_M :: 24
MAX_INPUT :: 98

@(export)
kkt_mst_sampling_filter :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<6 || length>MAX_INPUT do return -1
    n64:=input[0]; m64:=input[1]
    if n64<2 || n64>MAX_N || m64<1 || m64>MAX_M || length!=c.size_t(2+4*m64) do return -1
    n:=int(n64); m:=int(m64)
    eu:[MAX_M]i64; ev:[MAX_M]i64; ew:[MAX_M]i64; sample:[MAX_M]i64
    for i:=0;i<m;i+=1 {
        eu[i]=input[2+4*i];ev[i]=input[3+4*i];ew[i]=input[4+4*i];sample[i]=input[5+4*i]
        if eu[i]<0 || eu[i]>=ev[i] || ev[i]>=n64 || ew[i]<1 || ew[i]>1024 || (sample[i]!=0&&sample[i]!=1) do return -1
        for j:=0;j<i;j+=1 { if (eu[i]==eu[j]&&ev[i]==ev[j]) || ew[i]==ew[j] do return -1 }
    }
    if output==nil || capacity<c.size_t(m) do return -2
    order:[MAX_M]int;for i:=0;i<m;i+=1{order[i]=i}
    for i:=0;i<m;i+=1{best:=i;for j:=i+1;j<m;j+=1{if ew[order[j]]<ew[order[best]]{best=j}};tmp:=order[i];order[i]=order[best];order[best]=tmp}
    parent:[MAX_N]int;for i:=0;i<n;i+=1{parent[i]=i}
    in_forest:[MAX_M]bool;staged:[MAX_M]u8
    for pos:=0;pos<m;pos+=1{e:=order[pos];if sample[e]==0{continue};a:=int(eu[e]);b:=int(ev[e]);for parent[a]!=a{a=parent[a]};for parent[b]!=b{b=parent[b]};if a!=b{parent[b]=a;in_forest[e]=true}}
    for e:=0;e<m;e+=1{
        if in_forest[e]{staged[e]=1;continue}
        path_max:[MAX_N]i64;queue:[MAX_N]int;seen:[MAX_N]bool;for i:=0;i<n;i+=1{path_max[i]=-1}
        start:=int(eu[e]);target:=int(ev[e]);head:=0;tail:=1;queue[0]=start;seen[start]=true;path_max[start]=0
        for head<tail && !seen[target]{current:=queue[head];head+=1;for k:=0;k<m;k+=1{if !in_forest[k]{continue};next:=-1;if int(eu[k])==current{next=int(ev[k])}else if int(ev[k])==current{next=int(eu[k])};if next>=0&&!seen[next]{seen[next]=true;path_max[next]=max(path_max[current],ew[k]);queue[tail]=next;tail+=1}}}
        if !seen[target] || ew[e]<path_max[target] { staged[e]=1 } else { staged[e]=0 }
    }
    for i:=0;i<m;i+=1{output[i]=staged[i]}
    return i64(m)
}
