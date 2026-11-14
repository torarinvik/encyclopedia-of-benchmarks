package range_add_range_min
import "core:c"

Tree :: struct { minimum: [256]i64, lazy: [256]i64 }

build :: proc(t: ^Tree, input: [^]i64, node, left, right: int) {
    if right-left==1 { t.minimum[node]=input[2+left]; return }
    middle:=(left+right)/2
    build(t,input,2*node,left,middle)
    build(t,input,2*node+1,middle,right)
    t.minimum[node]=min(t.minimum[2*node],t.minimum[2*node+1])
}
push :: proc(t: ^Tree, node: int) {
    for child:=2*node; child<=2*node+1; child+=1 {
        t.minimum[child]+=t.lazy[node]; t.lazy[child]+=t.lazy[node]
    }
    t.lazy[node]=0
}
add :: proc(t: ^Tree, node, left, right, first, last: int, delta: i64) {
    if last<=left || right<=first { return }
    if first<=left && right<=last { t.minimum[node]+=delta; t.lazy[node]+=delta; return }
    push(t,node)
    middle:=(left+right)/2
    add(t,2*node,left,middle,first,last,delta)
    add(t,2*node+1,middle,right,first,last,delta)
    t.minimum[node]=min(t.minimum[2*node],t.minimum[2*node+1])
}
query :: proc(t: ^Tree, node, left, right, first, last: int) -> i64 {
    if last<=left || right<=first { return 9223372036854775807 }
    if first<=left && right<=last { return t.minimum[node] }
    push(t,node)
    middle:=(left+right)/2
    a:=query(t,2*node,left,middle,first,last)
    b:=query(t,2*node+1,middle,right,first,last)
    return min(a,b)
}
@(export)
range_add_range_min :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input==nil || length<2 || length>322 || input[0]<1 || input[0]>64 || input[1]<1 || input[1]>64 { return -1 }
    n:=int(input[0]); q:=int(input[1]); queries:=0
    if length!=c.size_t(2+n+4*q) { return -1 }
    for i:=0; i<n; i+=1 { if input[2+i]<-1000000 || input[2+i]>1000000 { return -1 } }
    for i:=0; i<q; i+=1 {
        base:=2+n+4*i
        op:=input[base]; left:=input[base+1]; right:=input[base+2]; delta:=input[base+3]
        if left<0 || left>=right || right>i64(n) { return -1 }
        if op==0 { if delta < -100000 || delta > 100000 { return -1 } } else if op==1 {
            if delta!=0 { return -1 }; queries+=1
        } else { return -1 }
    }
    if queries==0 { return -1 }
    if output==nil || capacity<c.size_t(8*queries) { return -2 }
    tree:Tree
    build(&tree,input,1,0,n)
    written:=0
    for i:=0; i<q; i+=1 {
        base:=2+n+4*i; left:=int(input[base+1]); right:=int(input[base+2])
        if input[base]==0 { add(&tree,1,0,n,left,right,input[base+3]) } else {
            bits:=transmute(u64)query(&tree,1,0,n,left,right)
            for byte:=0;byte<8;byte+=1 { output[8*written+byte]=u8((bits >> u64(8*byte)) & 255) }
            written+=1
        }
    }
    return i64(8*written)
}
