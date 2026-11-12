from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

alias MOD = 998244353
alias MAX_Q = 16
alias CAP = 4096

struct AffineNode:
    sum: Int64
    mul: Int64
    add: Int64
    left: Int
    right: Int

fn aff_norm(x0: Int64) -> Int64:
    let x = x0 % MOD
    if x < 0: return x + MOD
    return x

fn aff_clone(mut nodes: InlineArray[AffineNode, CAP], mut used: Int, source: Int) -> Int:
    if source < 0 or used >= CAP: return -1
    let copy = used
    used += 1
    nodes[copy] = nodes[source]
    return copy

fn aff_make(mut nodes: InlineArray[AffineNode, CAP], mut used: Int,
             value: Int64, left: Int, right: Int) -> Int:
    if used >= CAP: return -1
    let copy = used
    used += 1
    nodes[copy] = AffineNode(value, 1, 0, left, right)
    return copy

fn aff_apply(mut nodes: InlineArray[AffineNode, CAP], node: Int,
              m0: Int64, b0: Int64, length: Int):
    let m = aff_norm(m0)
    let b = aff_norm(b0)
    nodes[node].sum = aff_norm(m * nodes[node].sum + b * Int64(length))
    nodes[node].mul = aff_norm(m * nodes[node].mul)
    nodes[node].add = aff_norm(m * nodes[node].add + b)

fn aff_push(mut nodes: InlineArray[AffineNode, CAP], mut used: Int,
             node: Int, left: Int, right: Int) -> Bool:
    let m = nodes[node].mul
    let b = nodes[node].add
    if m == 1 and b == 0: return True
    if left < right:
        let middle = left + (right-left)//2
        let lc = aff_clone(mut nodes, mut used, nodes[node].left)
        let rc = aff_clone(mut nodes, mut used, nodes[node].right)
        if lc < 0 or rc < 0: return False
        nodes[node].left = lc
        nodes[node].right = rc
        aff_apply(mut nodes, lc, m, b, middle-left+1)
        aff_apply(mut nodes, rc, m, b, right-middle)
    nodes[node].mul = 1
    nodes[node].add = 0
    return True

fn aff_build(mut nodes: InlineArray[AffineNode, CAP], mut used: Int,
             input: UnsafePointer[Int64, ImmutAnyOrigin], offset: Int,
             left: Int, right: Int) -> Int:
    if left == right: return aff_make(mut nodes, mut used, input[offset+left], -1, -1)
    let middle = left + (right-left)//2
    let x = aff_build(mut nodes, mut used, input, offset, left, middle)
    let y = aff_build(mut nodes, mut used, input, offset, middle+1, right)
    if x < 0 or y < 0: return -1
    return aff_make(mut nodes, mut used, aff_norm(nodes[x].sum+nodes[y].sum), x, y)

fn aff_update(mut nodes: InlineArray[AffineNode, CAP], mut used: Int, root: Int,
              left: Int, right: Int, ql: Int, qr: Int, m: Int64, b: Int64) -> Int:
    if ql <= left and right <= qr:
        let x = aff_clone(mut nodes, mut used, root)
        if x < 0: return -1
        aff_apply(mut nodes, x, m, b, right-left+1)
        return x
    let x = aff_clone(mut nodes, mut used, root)
    if x < 0 or not aff_push(mut nodes, mut used, x, left, right): return -1
    let middle = left + (right-left)//2
    if ql <= middle:
        let y = aff_update(mut nodes, mut used, nodes[x].left, left, middle, ql, qr, m, b)
        if y < 0: return -1
        nodes[x].left = y
    if qr > middle:
        let y = aff_update(mut nodes, mut used, nodes[x].right, middle+1, right, ql, qr, m, b)
        if y < 0: return -1
        nodes[x].right = y
    nodes[x].sum = aff_norm(nodes[nodes[x].left].sum + nodes[nodes[x].right].sum)
    return x

fn aff_logical_child(mut nodes: InlineArray[AffineNode, CAP], mut used: Int,
                     source: Int, right_child: Bool, left: Int, right: Int) -> Int:
    var child = nodes[source].left
    if right_child: child = nodes[source].right
    let copy = aff_clone(mut nodes, mut used, child)
    if copy < 0: return -1
    let m=nodes[source].mul;let b=nodes[source].add
    if m != 1 or b != 0:
        let middle=left+(right-left)//2
        var count=middle-left+1
        if right_child: count=right-middle
        aff_apply(mut nodes,copy,m,b,count)
    return copy

fn aff_copy(mut nodes: InlineArray[AffineNode, CAP], mut used: Int,
            dst: Int, src: Int, left: Int, right: Int, ql: Int, qr: Int) -> Int:
    if ql <= left and right <= qr: return src
    let x=aff_clone(mut nodes,mut used,dst)
    if x < 0 or not aff_push(mut nodes,mut used,x,left,right): return -1
    let middle=left+(right-left)//2
    if ql <= middle:
        let s=aff_logical_child(mut nodes,mut used,src,False,left,right)
        if s<0:return -1
        let y=aff_copy(mut nodes,mut used,nodes[x].left,s,left,middle,ql,qr)
        if y<0:return -1
        nodes[x].left=y
    if qr > middle:
        let s=aff_logical_child(mut nodes,mut used,src,True,left,right)
        if s<0:return -1
        let y=aff_copy(mut nodes,mut used,nodes[x].right,s,middle+1,right,ql,qr)
        if y<0:return -1
        nodes[x].right=y
    nodes[x].sum=aff_norm(nodes[nodes[x].left].sum+nodes[nodes[x].right].sum)
    return x

fn aff_query(nodes: InlineArray[AffineNode, CAP], node: Int, left: Int, right: Int,
             ql: Int, qr: Int, cm: Int64, ca: Int64) -> Int64:
    if ql <= left and right <= qr:
        return aff_norm(cm*nodes[node].sum+ca*Int64(right-left+1))
    let middle=left+(right-left)//2
    let nm=aff_norm(cm*nodes[node].mul);let na=aff_norm(cm*nodes[node].add+ca)
    var z:Int64=0
    if ql<=middle:z=aff_query(nodes,nodes[node].left,left,middle,ql,qr,nm,na)
    if qr>middle:z=aff_norm(z+aff_query(nodes,nodes[node].right,middle+1,right,ql,qr,nm,na))
    return z

fn aff_put(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits=bitcast[UInt64](value)
    for byte in range(8): output[offset+byte]=UInt8((bits>>UInt(8*byte))&255)

@export("persistent_range_affine_range_sum")
fn persistent_range_affine_range_sum(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length:c_size_t, output:UnsafePointer[UInt8,MutAnyOrigin], capacity:c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>115:return -1
    let n0=input[0];let q0=input[1]
    if n0<1 or n0>16 or q0<1 or q0>16:return -1
    let n=Int(n0);let q=Int(q0);var off=2+n
    if length<c_size_t(off):return -1
    for j in range(n):if input[2+j]<0 or input[2+j]>=MOD:return -1
    var kind=InlineArray[Int64,MAX_Q]();var refs=InlineArray[Int64,MAX_Q]();var src=InlineArray[Int64,MAX_Q]()
    var starts=InlineArray[Int64,MAX_Q]();var ends=InlineArray[Int64,MAX_Q]();var mults=InlineArray[Int64,MAX_Q]();var adds=InlineArray[Int64,MAX_Q]()
    for i in range(MAX_Q):mults[i]=1
    for i in range(q):
        if off>=Int(length):return -1
        let op=input[off];var width=0
        if op==0:width=6
        elif op==1:width=5
        elif op==2:width=4
        else:return -1
        if Int(length)-off<width:return -1
        let k=input[off+1]
        if k < -1 or k >= Int64(i):return -1
        if k>=0 and kind[Int(k)]!=0 and kind[Int(k)]!=1:return -1
        kind[i]=op;refs[i]=k
        if op==0 or op==2:
            starts[i]=input[off+2];ends[i]=input[off+3]
            if starts[i]<0 or ends[i]<=starts[i] or ends[i]>n0:return -1
        if op==0:
            mults[i]=input[off+4];adds[i]=input[off+5]
            if mults[i]<1 or mults[i]>=MOD or adds[i]<0 or adds[i]>=MOD:return -1
        if op==1:
            src[i]=input[off+2];starts[i]=input[off+3];ends[i]=input[off+4]
            let s=src[i]
            if s < -1 or s>=Int64(i):return -1
            if s>=0 and kind[Int(s)]!=0 and kind[Int(s)]!=1:return -1
            if starts[i]<0 or ends[i]<=starts[i] or ends[i]>n0:return -1
        off+=width
    if off!=Int(length):return -1
    var nodes=InlineArray[AffineNode,CAP]();var used=0
    let initial=aff_build(mut nodes,mut used,input,2,0,n-1)
    if initial<0:return -1
    var roots=InlineArray[Int,MAX_Q]();var answers=InlineArray[Int64,MAX_Q]();var answer_count=0
    for i in range(q):
        var base=initial
        if refs[i]>=0:base=roots[Int(refs[i])]
        if kind[i]==0:
            roots[i]=aff_update(mut nodes,mut used,base,0,n-1,Int(starts[i]),Int(ends[i])-1,mults[i],adds[i])
            if roots[i]<0:return -1
        elif kind[i]==1:
            var source=initial
            if src[i]>=0:source=roots[Int(src[i])]
            roots[i]=aff_copy(mut nodes,mut used,base,source,0,n-1,Int(starts[i]),Int(ends[i])-1)
            if roots[i]<0:return -1
        else:
            answers[answer_count]=aff_query(nodes,base,0,n-1,Int(starts[i]),Int(ends[i])-1,1,0)
            answer_count+=1
    let bytes=8*answer_count
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(answer_count):aff_put(output,8*i,answers[i])
    return Int64(bytes)
