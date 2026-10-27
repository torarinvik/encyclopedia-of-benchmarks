package randomized_contraction_edge_sampling
import "core:c"

MAX_N :: 16
MAX_M :: 24
MAX_INPUT :: 74

put32 :: proc(out: [^]u8, pos: int, value: i32) {
    bits:=u32(value)
    for j:=0;j<4;j+=1 { out[pos+j]=u8(bits&255);bits>>=8 }
}

@(export)
randomized_contraction_edge_sampling :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<5 || length>MAX_INPUT do return -1
    n64:=input[0];m64:=input[1]
    if n64<2 || n64>MAX_N || m64<n64-1 || m64>MAX_M || length!=c.size_t(2+3*m64) do return -1
    n:=int(n64);m:=int(m64)
    eu:[MAX_M]i64;ev:[MAX_M]i64;bits:[MAX_M]i64
    for i:=0;i<m;i+=1 {
        eu[i]=input[2+3*i];ev[i]=input[3+3*i];bits[i]=input[4+3*i]
        if eu[i]<0 || eu[i]>=ev[i] || ev[i]>=n64 || (bits[i]!=0&&bits[i]!=1) do return -1
        for j:=0;j<i;j+=1 { if eu[i]==eu[j]&&ev[i]==ev[j] do return -1 }
    }
    seen:[MAX_N]bool;queue:[MAX_N]int;head:=0;tail:=1;queue[0]=0;seen[0]=true
    for head<tail {
        current:=queue[head];head+=1
        for e:=0;e<m;e+=1 {
            next:=-1;if int(eu[e])==current {next=int(ev[e])} else if int(ev[e])==current {next=int(eu[e])}
            if next>=0&&!seen[next] {seen[next]=true;queue[tail]=next;tail+=1}
        }
    }
    if tail!=n do return -1
    parent:[MAX_N]int;for i:=0;i<n;i+=1{parent[i]=i}
    for e:=0;e<m;e+=1 {if bits[e]!=0 {a:=int(eu[e]);b:=int(ev[e]);for parent[a]!=a{a=parent[a]};for parent[b]!=b{b=parent[b]};if a!=b{parent[b]=a}}}
    minimum:[MAX_N]int;for i:=0;i<n;i+=1{minimum[i]=n}
    for vertex:=0;vertex<n;vertex+=1{root:=vertex;for parent[root]!=root{root=parent[root]};minimum[root]=min(minimum[root],vertex)}
    bytes:=4*n;if output==nil||capacity<c.size_t(bytes) do return -2
    staged:[4*MAX_N]u8
    for vertex:=0;vertex<n;vertex+=1{root:=vertex;for parent[root]!=root{root=parent[root]};put32(&staged[0],4*vertex,i32(minimum[root]))}
    for i:=0;i<bytes;i+=1{output[i]=staged[i]}
    return i64(bytes)
}
