from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
struct SplayNode:
    var key:Int32
    var left:Int32
    var right:Int32
    fn __init__(out self,key:Int32=0,left:Int32= -1,right:Int32= -1):self.key=key;self.left=left;self.right=right
fn rotate_r(a:UnsafePointer[SplayNode,MutAnyOrigin],root:Int32)->Int32:
    let child=a[root].left;a[root].left=a[child].right;a[child].right=root;return child
fn rotate_l(a:UnsafePointer[SplayNode,MutAnyOrigin],root:Int32)->Int32:
    let child=a[root].right;a[root].right=a[child].left;a[child].left=root;return child
fn splay(a:UnsafePointer[SplayNode,MutAnyOrigin],root0:Int32,key:Int32)->Int32:
    if root0<0 or a[root0].key==key:return root0
    var root=root0
    if key<a[root].key:
        let left=a[root].left
        if left<0:return root
        if key<a[left].key:
            let child=splay(a,a[left].left,key);a[left].left=child;let rotated=rotate_r(a,root)
            if a[rotated].left<0:return rotated
            return rotate_r(a,rotated)
        elif key>a[left].key:
            let child=splay(a,a[left].right,key);a[left].right=child
            if child>=0:let nl=rotate_l(a,left);a[root].left=nl
        if a[root].left<0:return root
        return rotate_r(a,root)
    else:
        let right=a[root].right
        if right<0:return root
        if key>a[right].key:
            let child=splay(a,a[right].right,key);a[right].right=child;let rotated=rotate_l(a,root)
            if a[rotated].right<0:return rotated
            return rotate_l(a,rotated)
        elif key<a[right].key:
            let child=splay(a,a[right].left,key);a[right].left=child
            if child>=0:let nr=rotate_r(a,right);a[root].right=nr
        if a[root].right<0:return root
        return rotate_l(a,root)
fn inorder_splay(a:UnsafePointer[SplayNode,ImmutAnyOrigin],root:Int32,out:UnsafePointer[Int64,MutAnyOrigin],count:Int)->Int:
    if root<0:return count
    var next=inorder_splay(a,a[root].left,out,count);out[next]=Int64(a[root].key);next+=1;return inorder_splay(a,a[root].right,out,next)
@export("splay_tree")
fn splay_tree(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n==0 or n>130:return -1
    let oc=v[0]
    if oc<0 or oc>64 or n!=c_size_t(1+2*oc):return -1
    let ops=Int(oc);var live=InlineArray[Int64,32](fill=0);var lc=0
    for i in range(ops):
        let op=v[1+2*i];let key=v[2+2*i]
        if (op!=0 and op!=1 and op!=2) or key< -2147483648 or key>2147483647:return -1
        var idx=0
        while idx<lc and live[idx]!=key:idx+=1
        if op==0:
            if idx<lc or lc>=32:return -1
            live[lc]=key;lc+=1
        elif op==2:
            if lc==0:return -1
            if idx<lc:live[idx]=live[lc-1];lc-=1
    var nodes=InlineArray[SplayNode,64](fill=SplayNode());var nodecount=0;var root:Int32= -1;var tags=InlineArray[Int64,64](fill=0)
    for i in range(ops):
        let op=v[1+2*i];let key=Int32(v[2+2*i])
        if op==0:
            if root<0:
                nodes[nodecount]=SplayNode(key);root=Int32(nodecount);nodecount+=1
            else:
                root=splay(nodes.unsafe_ptr(),root,key);nodes[nodecount]=SplayNode(key);let fresh=Int32(nodecount);nodecount+=1
                if key<nodes[root].key:nodes[fresh].left=nodes[root].left;nodes[fresh].right=root;nodes[root].left= -1
                else:nodes[fresh].right=nodes[root].right;nodes[fresh].left=root;nodes[root].right= -1
                root=fresh
            tags[i]= -2
        elif op==1:
            root=splay(nodes.unsafe_ptr(),root,key);tags[i]=1 if root>=0 and nodes[root].key==key else 0
        else:
            root=splay(nodes.unsafe_ptr(),root,key);tags[i]= -3
            if nodes[root].key==key:
                let l=nodes[root].left;let r=nodes[root].right
                if l<0:root=r
                else:root=splay(nodes.unsafe_ptr(),l,key);nodes[root].right=r
    var keys=InlineArray[Int64,32](fill=0);let kc=inorder_splay(UnsafePointer[SplayNode,ImmutAnyOrigin](nodes.unsafe_ptr()),root,keys.unsafe_ptr(),0)
    var staged=InlineArray[Int64,98](fill=0);staged[0]=oc
    for i in range(ops):staged[i+1]=tags[i]
    staged[ops+1]=kc
    for i in range(kc):staged[ops+2+i]=keys[i]
    let words=ops+2+kc;let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(words):let bits=bitcast[UInt64](staged[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
