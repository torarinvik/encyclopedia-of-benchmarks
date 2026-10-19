from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
struct PSTLNode(Copyable):
    var sum:Int64
    var prop:Int64
    var left:Int32
    var right:Int32
fn psl_make(mut nodes:InlineArray[PSTLNode,16384],mut used:Int,sum:Int64,prop:Int64,left:Int32,right:Int32)->Int:
    if used>=16384:return -1
    let ix=used;nodes[ix]=PSTLNode(sum,prop,left,right);used+=1;return ix
fn psl_clone(mut nodes:InlineArray[PSTLNode,16384],mut used:Int,src:Int)->Int:
    if src<0 or used>=16384:return -1
    let ix=used;nodes[ix]=nodes[src];used+=1;return ix
fn psl_push(mut nodes:InlineArray[PSTLNode,16384],mut used:Int,node:Int,lo:Int,hi:Int)->Bool:
    let prop=nodes[node].prop
    if prop==0:return True
    nodes[node].sum+=Int64(hi-lo+1)*prop
    if lo!=hi:
        let l=psl_clone(mut nodes,mut used,Int(nodes[node].left));let r=psl_clone(mut nodes,mut used,Int(nodes[node].right))
        if l<0 or r<0:return False
        nodes[node].left=Int32(l);nodes[node].right=Int32(r);nodes[l].prop+=prop;nodes[r].prop+=prop
    nodes[node].prop=0;return True
fn psl_build(mut nodes:InlineArray[PSTLNode,16384],mut used:Int,v:UnsafePointer[Int64,ImmutAnyOrigin],lo:Int,hi:Int)->Int:
    if lo==hi:return psl_make(mut nodes,mut used,v[2+lo],0,-1,-1)
    let mid=lo+(hi-lo)/2;let a=psl_build(mut nodes,mut used,v,lo,mid);let b=psl_build(mut nodes,mut used,v,mid+1,hi)
    if a<0 or b<0:return -1
    return psl_make(mut nodes,mut used,nodes[a].sum+nodes[b].sum,0,Int32(a),Int32(b))
fn psl_update(mut nodes:InlineArray[PSTLNode,16384],mut used:Int,current:Int,lo:Int,hi:Int,ql:Int,qr:Int,delta:Int64)->Int:
    if not psl_push(mut nodes,mut used,current,lo,hi):return -1
    if lo>=ql and hi<=qr:
        let copy=psl_clone(mut nodes,mut used,current);if copy<0:return -1
        nodes[copy].prop+=delta
        if not psl_push(mut nodes,mut used,copy,lo,hi):return -1
        return copy
    if lo>qr or hi<ql:return current
    let copy=psl_make(mut nodes,mut used,0,0,-1,-1);if copy<0:return -1
    let mid=lo+(hi-lo)/2;let a=psl_update(mut nodes,mut used,Int(nodes[current].left),lo,mid,ql,qr,delta);let b=psl_update(mut nodes,mut used,Int(nodes[current].right),mid+1,hi,ql,qr,delta)
    if a<0 or b<0:return -1
    nodes[copy].left=Int32(a);nodes[copy].right=Int32(b);nodes[copy].sum=nodes[a].sum+nodes[b].sum;return copy
fn psl_query(mut nodes:InlineArray[PSTLNode,16384],mut used:Int,node:Int,lo:Int,hi:Int,ql:Int,qr:Int,mut ok:Bool)->Int64:
    if not psl_push(mut nodes,mut used,node,lo,hi):ok=False;return 0
    if hi<ql or qr<lo:return 0
    if ql<=lo and hi<=qr:return nodes[node].sum
    let mid=lo+(hi-lo)/2;let a=psl_query(mut nodes,mut used,Int(nodes[node].left),lo,mid,ql,qr,mut ok)
    if not ok:return 0
    let b=psl_query(mut nodes,mut used,Int(nodes[node].right),mid+1,hi,ql,qr,mut ok);return a+b
fn psl_hash(mut h:UInt64,x:Int64)->UInt64:
    let u=UInt64(x)
    for b in range(8):h=(h^UInt64((u>>(8*b))&255))*1099511628211
    return h
@export("persistent_seg_tree_lazy_prop")
fn persistent_seg_tree_lazy_prop(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>386:return -1
    let size=Int(v[0]);let q=Int(v[1]);if size<1 or size>64 or q<0 or q>64 or Int(n)!=2+size+4*q:return -1
    for i in range(size):if v[2+i] < -1000 or v[2+i]>1000:return -1
    var nodes=InlineArray[PSTLNode,16384](fill=PSTLNode(0,0,-1,-1));var used=0;var roots=InlineArray[Int64,65](fill=0)
    let initial=psl_build(mut nodes,mut used,v,0,size-1);if initial<0:return -1;roots[0]=Int64(initial);var versions=1;var queries=0;var sums=InlineArray[Int64,64](fill=0);var p=2+size
    for _ in range(q):
        let op=v[p];let a=v[p+1];let b=v[p+2];let c=v[p+3];p+=4
        if op==0:
            if a<0 or a>b or b>=size or c < -1000 or c>1000:return -1
            let root=psl_update(mut nodes,mut used,Int(roots[versions-1]),0,size-1,Int(a),Int(b),c);if root<0:return -1;roots[versions]=Int64(root);versions+=1
        elif op==1:
            if a<0 or a>=versions or b<0 or c<b or c>=size:return -1
            var ok=True;let ans=psl_query(mut nodes,mut used,Int(roots[Int(a)]),0,size-1,Int(b),Int(c),mut ok);if not ok:return -1;sums[queries]=ans;queries+=1
        else:return -1
    var h:UInt64=14695981039346656037;h=psl_hash(h,Int64(versions));h=psl_hash(h,Int64(queries));for i in range(queries):h=psl_hash(h,sums[i])
    return Int64(h&0x7fffffffffffffff)
