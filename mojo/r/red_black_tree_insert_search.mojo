from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
comptime RBIS_MAX=128
@fieldwise_init
struct RBISNode:
    var key:Int64
    var left:Int
    var right:Int
    var red:Bool
fn rbis_red(t:InlineArray[RBISNode,RBIS_MAX+1],node:Int)->Bool:return node!=0 and t[node].red
fn rbis_flip(mut t:InlineArray[RBISNode,RBIS_MAX+1],node:Int):
    t[node].red=not t[node].red;let l=t[node].left;let r=t[node].right;t[l].red=not t[l].red;t[r].red=not t[r].red
fn rbis_rotate_left(mut t:InlineArray[RBISNode,RBIS_MAX+1],node:Int)->Int:
    let pivot=t[node].right;let left=t[pivot].left;t[node].right=left;t[pivot].left=node;t[pivot].red=t[node].red;t[node].red=True;return pivot
fn rbis_rotate_right(mut t:InlineArray[RBISNode,RBIS_MAX+1],node:Int)->Int:
    let pivot=t[node].left;let right=t[pivot].right;t[node].left=right;t[pivot].right=node;t[pivot].red=t[node].red;t[node].red=True;return pivot
fn rbis_insert(mut t:InlineArray[RBISNode,RBIS_MAX+1],node:Int,key:Int64,mut next:Int)->Int:
    if node==0:
        let created=next;next+=1;t[created]=RBISNode(key=key,left=0,right=0,red=True);return created
    if rbis_red(t,t[node].left) and rbis_red(t,t[node].right):rbis_flip(t,node)
    if key==t[node].key:t[node].key=key
    elif key<t[node].key:t[node].left=rbis_insert(t,t[node].left,key,next)
    else:t[node].right=rbis_insert(t,t[node].right,key,next)
    if rbis_red(t,t[node].right) and not rbis_red(t,t[node].left):return rbis_rotate_left(t,node)
    if rbis_red(t,t[node].left) and rbis_red(t,t[t[node].left].left):return rbis_rotate_right(t,node)
    return node
fn rbis_find(t:InlineArray[RBISNode,RBIS_MAX+1],node0:Int,key:Int64)->Int:
    var node=node0
    while node!=0:
        if key<t[node].key:node=t[node].left
        elif key>t[node].key:node=t[node].right
        else:return node
    return 0
fn rbis_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[at+j]=UInt8((b>>(8*j))&UInt64(255))
@export("red_black_tree_insert_search")
fn red_black_tree_insert_search(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>128 or Int(n)!=1+2*Int(v[0]):return -1
    let ops=Int(v[0])
    for i in range(ops):let op=v[1+2*i];let key=v[2+2*i];if (op!=0 and op!=1) or key< -2147483648 or key>2147483647:return -1
    var tree=InlineArray[RBISNode,RBIS_MAX+1](fill=RBISNode(key=0,left=0,right=0,red=False));var root=0;var next=1
    var keys=InlineArray[Int64,128](fill=0);var nk=0;var searches=InlineArray[Int64,128](fill=0);var ns=0
    for i in range(ops):
        let op=v[1+2*i];let key=v[2+2*i]
        if op==0:
            if rbis_find(tree,root,key)!=0:return -1
            root=rbis_insert(tree,root,key,next);tree[root].red=False;keys[nk]=key;nk+=1
        else:searches[ns]=if rbis_find(tree,root,key)!=0:1 else:0;ns+=1
    for i in range(1,nk):let x=keys[i];var j=i;while j>0 and keys[j-1]>x:keys[j]=keys[j-1];j-=1;keys[j]=x
    let words=2+nk+ns;let bytes=8*words
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var at=0;rbis_put(o,at,Int64(nk));at+=8
    for i in range(nk):rbis_put(o,at,keys[i]);at+=8
    rbis_put(o,at,Int64(ns));at+=8
    for i in range(ns):rbis_put(o,at,searches[i]);at+=8
    return Int64(bytes)
