from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
struct PSTNode(Copyable):
    var sum:Int64
    var left:Int32
    var right:Int32
fn pst_make(mut nodes:InlineArray[PSTNode,640],mut used:Int,sum:Int64,left:Int32,right:Int32)->Int:
    if used>=640:return -1
    let i=used;nodes[i]=PSTNode(sum,left,right);used+=1;return i
fn pst_build(mut nodes:InlineArray[PSTNode,640],mut used:Int,v:UnsafePointer[Int64,ImmutAnyOrigin],lo:Int,hi:Int)->Int:
    if lo==hi:return pst_make(mut nodes,mut used,v[2+lo],-1,-1)
    let mid=lo+(hi-lo)/2;let a=pst_build(mut nodes,mut used,v,lo,mid);let b=pst_build(mut nodes,mut used,v,mid+1,hi)
    if a<0 or b<0:return -1
    return pst_make(mut nodes,mut used,nodes[a].sum+nodes[b].sum,Int32(a),Int32(b))
fn pst_set(mut nodes:InlineArray[PSTNode,640],mut used:Int,root:Int,lo:Int,hi:Int,index:Int,value:Int64)->Int:
    if lo==hi:return pst_make(mut nodes,mut used,value,-1,-1)
    let mid=lo+(hi-lo)/2;var a=Int(nodes[root].left);var b=Int(nodes[root].right)
    if index<=mid:a=pst_set(mut nodes,mut used,a,lo,mid,index,value)
    else:b=pst_set(mut nodes,mut used,b,mid+1,hi,index,value)
    if a<0 or b<0:return -1
    return pst_make(mut nodes,mut used,nodes[a].sum+nodes[b].sum,Int32(a),Int32(b))
fn pst_query(nodes:InlineArray[PSTNode,640],root:Int,lo:Int,hi:Int,ql:Int,qr:Int)->Int64:
    if ql<=lo and hi<=qr:return nodes[root].sum
    let mid=lo+(hi-lo)/2;var total:Int64=0
    if ql<=mid:total+=pst_query(nodes,Int(nodes[root].left),lo,mid,ql,qr)
    if qr>mid:total+=pst_query(nodes,Int(nodes[root].right),mid+1,hi,ql,qr)
    return total
fn pst_hash(mut h:UInt64,x:Int64)->UInt64:
    let u=UInt64(x)
    for b in range(8):h=(h^UInt64((u>>(8*b))&255))*1099511628211
    return h
@export("persistent_segment_tree")
fn persistent_segment_tree(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>322:return -1
    let size=Int(v[0]);let q=Int(v[1]);if size<1 or size>64 or q<0 or q>64 or Int(n)!=2+size+4*q:return -1
    for i in range(size):if v[2+i] < -1000 or v[2+i]>1000:return -1
    var nodes=InlineArray[PSTNode,640](fill=PSTNode(0,-1,-1));var used=0;var roots=InlineArray[Int64,65](fill=0)
    roots[0]=Int64(pst_build(mut nodes,mut used,v,0,size-1));if roots[0]<0:return -1
    var versions=1;var queries=0;var sums=InlineArray[Int64,64](fill=0);var p=2+size
    for _ in range(q):
        let op=v[p];let a=v[p+1];let b=v[p+2];let c=v[p+3];p+=4
        if op==0:
            if a<0 or a>=versions or b<0 or b>=size or c < -1000 or c>1000:return -1
            let root=pst_set(mut nodes,mut used,Int(roots[Int(a)]),0,size-1,Int(b),c);if root<0:return -1;roots[versions]=Int64(root);versions+=1
        elif op==1:
            if a<0 or a>=versions or b<0 or c<b or c>=size:return -1
            sums[queries]=pst_query(nodes,Int(roots[Int(a)]),0,size-1,Int(b),Int(c));queries+=1
        else:return -1
    var h:UInt64=14695981039346656037;h=pst_hash(h,Int64(versions));h=pst_hash(h,Int64(queries));for i in range(queries):h=pst_hash(h,sums[i])
    return Int64(h&0x7fffffffffffffff)
