from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias N = 64
alias Q = 64
alias E = 127
alias B = 127
alias L = 8
alias M = 4

@export("rmq_cartesian_tree_fcb")
fn rmq_cartesian_tree_fcb(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 195: return -1
    if input[0] < 1 or input[0] > N or input[1] < 0 or input[1] > Q: return -1
    let n = Int(input[0]); let q = Int(input[1]); let qo = 2+n
    if length != c_size_t(qo+2*q): return -1
    var values = InlineArray[Int64,N]()
    for i in range(n):
        values[i] = input[2+i]
        if values[i] < -1000 or values[i] > 1000: return -1
    for i in range(q):
        let lo=input[qo+2*i]; let hi=input[qo+2*i+1]
        if lo < 0 or lo > hi or hi >= n: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(q+1): return -2

    var left=InlineArray[Int,N](); var right=InlineArray[Int,N](); var parent=InlineArray[Int,N](); var mono=InlineArray[Int,N]()
    for i in range(n): left[i]=-1; right[i]=-1; parent[i]=-1
    var top=0
    for i in range(n):
        var last=-1
        while top>0 and values[mono[top-1]]>values[i]:
            top-=1; last=mono[top]
        if top>0:
            let p=mono[top-1]; right[p]=i; parent[i]=p
        if last>=0: left[i]=last; parent[last]=i
        mono[top]=i; top+=1
    var root=0
    while parent[root]>=0: root+=1

    var euler=InlineArray[Int,E](); var depth=InlineArray[Int,E](); var first=InlineArray[Int,N](); var nodeDepth=InlineArray[Int,N]()
    var frameNode=InlineArray[Int,N](); var state=InlineArray[Int,N]()
    var ec=1; var sp=1; euler[0]=root; depth[0]=0; first[root]=0; nodeDepth[root]=0; frameNode[0]=root
    while sp>0:
        let slot=sp-1; let v=frameNode[slot]
        if state[slot]==0:
            if left[v]>=0:
                let c=left[v]; state[slot]=1; nodeDepth[c]=nodeDepth[v]+1; first[c]=ec; euler[ec]=c; depth[ec]=nodeDepth[c]; ec+=1; frameNode[sp]=c; state[sp]=0; sp+=1
            elif right[v]>=0:
                let c=right[v]; state[slot]=2; nodeDepth[c]=nodeDepth[v]+1; first[c]=ec; euler[ec]=c; depth[ec]=nodeDepth[c]; ec+=1; frameNode[sp]=c; state[sp]=0; sp+=1
            else: sp-=1
        elif state[slot]==1:
            euler[ec]=v; depth[ec]=nodeDepth[v]; ec+=1
            if right[v]>=0:
                let c=right[v]; state[slot]=2; nodeDepth[c]=nodeDepth[v]+1; first[c]=ec; euler[ec]=c; depth[ec]=nodeDepth[c]; ec+=1; frameNode[sp]=c; state[sp]=0; sp+=1
            else: sp-=1
        else:
            euler[ec]=v; depth[ec]=nodeDepth[v]; ec+=1; sp-=1

    var lg=0; var x=ec
    while x>1: x=x//2; lg+=1
    let bs=max(1,lg//2); let blocks=(ec+bs-1)//bs
    var micro=InlineArray[Int,8*16](); var pat=InlineArray[Int,B](); var logs=InlineArray[Int,B+1](); var macro=InlineArray[Int,L*B]()
    for shape in range(1 << (bs-1)):
        var rel=InlineArray[Int,M]()
        for j in range(bs-1): rel[j+1]=rel[j]+(if ((shape>>j)&1)!=0: 1 else: -1)
        for a in range(bs):
            for z in range(a,bs):
                var best=a
                for k in range(a+1,z+1):
                    if rel[k]<rel[best]: best=k
                micro[shape*16+a*4+z]=best
    for b in range(blocks):
        let base=b*bs; let endAt=min(ec,base+bs); var best=base
        for j in range(base,endAt-1):
            if depth[j+1]>depth[j]: pat[b] |= 1 << (j-base)
            let c=j+1
            if depth[c]<depth[best] or (depth[c]==depth[best] and c<best): best=c
        macro[b]=best
    for c in range(2,blocks+1): logs[c]=logs[c//2]+1
    var levels=1
    while (1<<levels)<=blocks and levels<L:
        let half=1<<(levels-1); let span=2*half
        for b in range(blocks-span+1):
            let a=macro[(levels-1)*B+b]; let z=macro[(levels-1)*B+b+half]
            macro[levels*B+b]=if depth[a]<depth[z] or (depth[a]==depth[z] and a<z): a else: z
        levels+=1
    var answers=InlineArray[UInt8,Q]()
    for i in range(q):
        let u=Int(input[qo+2*i]); let v=Int(input[qo+2*i+1]); var a=first[u]; var z=first[v]
        if a>z: let t=a; a=z; z=t
        let ba=a//bs; let bz=z//bs; var best=0
        if ba==bz: best=ba*bs+micro[pat[ba]*16+(a%bs)*4+(z%bs)]
        else:
            let xa=ba*bs; let xz=bz*bs; let na=min(bs,ec-xa)
            best=xa+micro[pat[ba]*16+(a%bs)*4+na-1]
            let rb=xz+micro[pat[bz]*16+(z%bs)]
            if depth[rb]<depth[best] or (depth[rb]==depth[best] and rb<best): best=rb
            if bz>ba+1:
                let lo=ba+1; let hi=bz-1; let count=hi-lo+1; let k=logs[count]; let span=1<<k
                let aa=macro[k*B+lo]; let zz=macro[k*B+hi-span+1]
                let mid=if depth[aa]<depth[zz] or (depth[aa]==depth[zz] and aa<zz): aa else: zz
                if depth[mid]<depth[best] or (depth[mid]==depth[best] and mid<best): best=mid
        answers[i]=UInt8(euler[best])
    output[0]=UInt8(q)
    for i in range(q): output[i+1]=answers[i]
    Int64(q+1)
