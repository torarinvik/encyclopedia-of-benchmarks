from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer

fn add_apply(mut tree:InlineArray[Int64,512],mut lazy:InlineArray[Int64,512],node:Int,len:Int,delta:Int64):
    tree[node]+=delta*Int64(len);lazy[node]+=delta
fn add_push(mut tree:InlineArray[Int64,512],mut lazy:InlineArray[Int64,512],node:Int,len:Int):
    if len>1 and lazy[node]!=0:
        let half=len/2;add_apply(tree,lazy,node*2,half,lazy[node]);add_apply(tree,lazy,node*2+1,half,lazy[node]);lazy[node]=0
fn add_range(mut tree:InlineArray[Int64,512],mut lazy:InlineArray[Int64,512],node:Int,lo:Int,hi:Int,ql:Int,qh:Int,d:Int64):
    if ql<=lo and hi<=qh:add_apply(tree,lazy,node,hi-lo,d);return
    add_push(tree,lazy,node,hi-lo);let mid=(lo+hi)/2
    if ql<mid:add_range(tree,lazy,node*2,lo,mid,ql,qh,d)
    if qh>mid:add_range(tree,lazy,node*2+1,mid,hi,ql,qh,d)
    tree[node]=tree[node*2]+tree[node*2+1]
fn sum_range(mut tree:InlineArray[Int64,512],mut lazy:InlineArray[Int64,512],node:Int,lo:Int,hi:Int,ql:Int,qh:Int)->Int64:
    if ql<=lo and hi<=qh:return tree[node]
    add_push(tree,lazy,node,hi-lo);let mid=(lo+hi)/2;var result:Int64=0
    if ql<mid:result+=sum_range(tree,lazy,node*2,lo,mid,ql,qh)
    if qh>mid:result+=sum_range(tree,lazy,node*2+1,mid,hi,ql,qh)
    return result

@export("lazy_segment_tree_range_add_sum")
fn lazy_segment_tree_range_add_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>2306:return -1
    let nv=v[0]
    if nv<1 or nv>256 or n<c_size_t(nv+2):return -1
    let nq=v[Int(nv)+1]
    if nq<0 or nq>512 or n!=c_size_t(nv+2+4*nq):return -1
    for i in range(Int(nv)):
        if v[i+1]<-1000000 or v[i+1]>1000000:return -1
    for i in range(Int(nq)):
        let p=Int(nv)+2+4*i;let op=v[p];let l=v[p+1];let r=v[p+2];let d=v[p+3]
        if l<0 or l>=r or r>nv:return -1
        if op==0:
            if d < -1000000 or d>1000000:return -1
        elif op==1:
            if d!=0:return -1
        else:return -1
    var base=1
    while base<Int(nv):base*=2
    var tree=InlineArray[Int64,512](fill=0);var lazy=InlineArray[Int64,512](fill=0)
    for i in range(Int(nv)):tree[base+i]=v[i+1]
    var node=base-1
    while node>0:tree[node]=tree[node*2]+tree[node*2+1];node-=1
    var checksum:Int64=0
    for i in range(Int(nq)):
        let p=Int(nv)+2+4*i;let l=Int(v[p+1]);let r=Int(v[p+2])
        if v[p]==0:add_range(tree,lazy,1,0,base,l,r,v[p+3])
        else:checksum+=sum_range(tree,lazy,1,0,base,l,r)+131328000001
    return checksum
