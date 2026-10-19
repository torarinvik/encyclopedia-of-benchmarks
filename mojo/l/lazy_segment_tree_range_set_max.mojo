from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

fn set_build(node:Int,l:Int,r:Int,v:UnsafePointer[Int64,ImmutAnyOrigin],mut tree:InlineArray[Int64,1024]):
    if l==r:tree[node]=v[2+l];return
    let m=(l+r)/2;set_build(node*2,l,m,v,tree);set_build(node*2+1,m+1,r,v,tree);tree[node]=max(tree[node*2],tree[node*2+1])
fn set_push(node:Int,l:Int,r:Int,mut tree:InlineArray[Int64,1024],mut lazy:InlineArray[Int64,1024],mut pending:InlineArray[Int64,1024]):
    if pending[node]==0:return
    tree[node]=lazy[node];pending[node]=0
    if l<r:
        lazy[node*2]=tree[node];lazy[node*2+1]=tree[node];pending[node*2]=1;pending[node*2+1]=1
fn set_range(node:Int,l:Int,r:Int,ql:Int,qr:Int,x:Int64,mut tree:InlineArray[Int64,1024],mut lazy:InlineArray[Int64,1024],mut pending:InlineArray[Int64,1024]):
    set_push(node,l,r,tree,lazy,pending)
    if r<ql or l>qr:return
    if ql<=l and r<=qr:
        tree[node]=x
        if l<r:lazy[node*2]=x;lazy[node*2+1]=x;pending[node*2]=1;pending[node*2+1]=1
        return
    let m=(l+r)/2;set_range(node*2,l,m,ql,qr,x,tree,lazy,pending);set_range(node*2+1,m+1,r,ql,qr,x,tree,lazy,pending);tree[node]=max(tree[node*2],tree[node*2+1])
fn set_max(node:Int,l:Int,r:Int,ql:Int,qr:Int,mut tree:InlineArray[Int64,1024],mut lazy:InlineArray[Int64,1024],mut pending:InlineArray[Int64,1024])->Int64:
    set_push(node,l,r,tree,lazy,pending)
    if r<ql or l>qr:return -9223372036854775808
    if ql<=l and r<=qr:return tree[node]
    let m=(l+r)/2;return max(set_max(node*2,l,m,ql,qr,tree,lazy,pending),set_max(node*2+1,m+1,r,ql,qr,tree,lazy,pending))

@export("lazy_segment_tree_range_set_max")
fn lazy_segment_tree_range_set_max(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>2306:return -1
    let nv=v[0];let nq=v[1]
    if nv<1 or nv>256 or nq<0 or nq>512 or n<c_size_t(2+nv):return -1
    for i in range(Int(nv)):
        if v[2+i]<-1000000 or v[2+i]>1000000:return -1
    var ops=InlineArray[Int64,512](fill=0);var left=InlineArray[Int64,512](fill=0);var right=InlineArray[Int64,512](fill=0);var assigned=InlineArray[Int64,512](fill=0);var p=2+Int(nv)
    for i in range(Int(nq)):
        if p>=Int(n):return -1
        let op=v[p];let width=if op==0:3 elif op==1:4 else:0
        if width==0 or p+width>Int(n):return -1
        let l=v[p+1];let r=v[p+2]
        if l<0 or l>=r or r>nv:return -1
        ops[i]=op;left[i]=l;right[i]=r
        if op==1:
            assigned[i]=v[p+3]
            if assigned[i]<-1000000 or assigned[i]>1000000:return -1
        p+=width
    if p!=Int(n):return -1
    var tree=InlineArray[Int64,1024](fill=0);var lazy=InlineArray[Int64,1024](fill=0);var pending=InlineArray[Int64,1024](fill=0)
    set_build(1,0,Int(nv)-1,v,tree);var checksum:Int64=0;var ordinal:Int64=0
    for i in range(Int(nq)):
        let l=Int(left[i]);let r=Int(right[i])-1
        if ops[i]==1:set_range(1,0,Int(nv)-1,l,r,assigned[i],tree,lazy,pending)
        else:ordinal+=1;checksum+=ordinal*(set_max(1,0,Int(nv)-1,l,r,tree,lazy,pending)+1000001)
    return checksum
