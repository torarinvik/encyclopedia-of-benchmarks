package rmq_cartesian_tree_fcb

import "core:c"

N :: 64
Q :: 64
E :: 127
B :: 127
L :: 8
M :: 4

shallower :: proc "contextless" (depth: ^[E]int, a, b: int) -> int {
    if depth^[a] < depth^[b] do return a
    if depth^[b] < depth^[a] do return b
    return min(a, b)
}

range_minimum :: proc "contextless" (a, z, ec, bs: int, depth: ^[E]int,
    pattern: ^[B]int, micro: ^[8*16]int, macro_table: ^[L*B]int, logs: ^[B+1]int) -> int {
    ba, bz, oa, oz := a/bs, z/bs, a%bs, z%bs
    if ba == bz do return ba*bs + micro^[(pattern^[ba]*4+oa)*4+oz]
    xa, xz := ba*bs, bz*bs
    na := min(bs, ec-xa)
    best := xa + micro^[(pattern^[ba]*4+oa)*4+na-1]
    best = shallower(depth, best, xz+micro^[(pattern^[bz]*4)*4+oz])
    if bz > ba+1 {
        lo, hi := ba+1, bz-1
        k := logs^[hi-lo+1]
        span := 1 << k
        best = shallower(depth, best, macro_table^[k*B+lo])
        best = shallower(depth, best, macro_table^[k*B+hi-span+1])
    }
    return best
}

@(export)
rmq_cartesian_tree_fcb :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 195 do return -1
    if input[0] < 1 || input[0] > N || input[1] < 0 || input[1] > Q do return -1
    n, q := int(input[0]), int(input[1])
    qo := 2+n
    if length != c.size_t(qo+2*q) do return -1
    values: [N]i64
    for i := 0; i < n; i += 1 { values[i] = input[2+i]; if values[i] < -1000 || values[i] > 1000 do return -1 }
    for i := 0; i < q; i += 1 { a,z := input[qo+2*i],input[qo+2*i+1]; if a<0||a>z||z>=i64(n) do return -1 }
    if output == nil || output_capacity < c.size_t(q+1) do return -2
    left,right,parent,mono: [N]int
    for i := 0; i < n; i += 1 { left[i]=-1; right[i]=-1; parent[i]=-1 }
    top := 0
    for i := 0; i < n; i += 1 {
        last := -1
        for top>0 && values[mono[top-1]]>values[i] { top-=1; last=mono[top] }
        if top>0 { p:=mono[top-1]; right[p]=i; parent[i]=p }
        if last>=0 { left[i]=last; parent[last]=i }
        mono[top]=i; top+=1
    }
    root:=0; for parent[root]>=0 { root+=1 }
    euler,depth: [E]int
    first,node_depth,frame_node,state: [N]int
    ec,sp:=1,1; euler[0]=root; depth[0]=0; first[root]=0; node_depth[root]=0; frame_node[0]=root
    for sp>0 {
        slot:=sp-1; v:=frame_node[slot]
        if state[slot]==0 {
            if left[v]>=0 { c0:=left[v]; state[slot]=1; node_depth[c0]=node_depth[v]+1; first[c0]=ec; euler[ec]=c0; depth[ec]=node_depth[c0]; ec+=1; frame_node[sp]=c0; state[sp]=0; sp+=1 }
            else if right[v]>=0 { c0:=right[v]; state[slot]=2; node_depth[c0]=node_depth[v]+1; first[c0]=ec; euler[ec]=c0; depth[ec]=node_depth[c0]; ec+=1; frame_node[sp]=c0; state[sp]=0; sp+=1 }
            else { sp-=1 }
        } else if state[slot]==1 {
            euler[ec]=v; depth[ec]=node_depth[v]; ec+=1
            if right[v]>=0 { c0:=right[v]; state[slot]=2; node_depth[c0]=node_depth[v]+1; first[c0]=ec; euler[ec]=c0; depth[ec]=node_depth[c0]; ec+=1; frame_node[sp]=c0; state[sp]=0; sp+=1 }
            else { sp-=1 }
        } else { euler[ec]=v; depth[ec]=node_depth[v]; ec+=1; sp-=1 }
    }
    lg:=0; x:=ec; for x>1 { x/=2; lg+=1 }; bs:=max(1,lg/2); blocks:=(ec+bs-1)/bs
    micro: [8*16]int; pattern: [B]int; logs: [B+1]int; macro_table: [L*B]int
    for shape:=0; shape<(1<<(bs-1)); shape+=1 {
        relative: [M]int
        for step:=0; step<bs-1; step+=1 { delta:= -1; if (shape>>step)&1 != 0 { delta=1 }; relative[step+1]=relative[step]+delta }
        for lo:=0;lo<bs;lo+=1 { for hi:=lo;hi<bs;hi+=1 { best:=lo; for k:=lo+1;k<=hi;k+=1 {if relative[k]<relative[best]{best=k}}; micro[shape*16+lo*4+hi]=best } }
    }
    for b:=0;b<blocks;b+=1 { base:=b*bs; end:=min(ec,base+bs); best:=base; for j:=base;j+1<end;j+=1 {if depth[j+1]>depth[j]{pattern[b]|=1<<(j-base)}; best=shallower(&depth,best,j+1)}; macro_table[b]=best }
    for count:=2;count<=blocks;count+=1 {logs[count]=logs[count/2]+1}
    level:=1; for (1<<level)<=blocks&&level<L {half:=1<<(level-1); span:=2*half; for b:=0;b+span<=blocks;b+=1 {macro_table[level*B+b]=shallower(&depth,macro_table[(level-1)*B+b],macro_table[(level-1)*B+b+half])}; level+=1}
    answers: [Q]u8
    for i:=0;i<q;i+=1 {a,z:=first[int(input[qo+2*i])],first[int(input[qo+2*i+1])]; if a>z {a,z=z,a}; at:=range_minimum(a,z,ec,bs,&depth,&pattern,&micro,&macro_table,&logs); answers[i]=u8(euler[at])}
    output[0]=u8(q); for i:=0;i<q;i+=1 {output[i+1]=answers[i]}; return i64(q+1)
}
