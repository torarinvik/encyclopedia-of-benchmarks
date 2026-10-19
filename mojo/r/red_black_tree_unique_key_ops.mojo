from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
comptime RBTU_MAX=128
@fieldwise_init
struct RBTUNode:
    var key:Int64
    var left:Int
    var right:Int
    var parent:Int
    var red:Bool
fn rbtu_find(t:InlineArray[RBTUNode,RBTU_MAX+1],root0:Int,key:Int64)->Int:
    var root=root0
    while root!=0 and t[root].key!=key:root=if key<t[root].key:t[root].left else:t[root].right
    return root
fn rbtu_left(mut t:InlineArray[RBTUNode,RBTU_MAX+1],mut root:Int,x:Int)->Int:
    let y=t[x].right;t[x].right=t[y].left
    if t[y].left!=0:let child=t[y].left;t[child].parent=x
    t[y].parent=t[x].parent;let parent=t[x].parent
    if parent==0:root=y
    elif x==t[parent].left:t[parent].left=y
    else:t[parent].right=y
    t[y].left=x;t[x].parent=y;return root
fn rbtu_right(mut t:InlineArray[RBTUNode,RBTU_MAX+1],mut root:Int,y:Int)->Int:
    let x=t[y].left;t[y].left=t[x].right
    if t[x].right!=0:let child=t[x].right;t[child].parent=y
    t[x].parent=t[y].parent;let parent=t[y].parent
    if parent==0:root=x
    elif y==t[parent].right:t[parent].right=x
    else:t[parent].left=x
    t[x].right=y;t[y].parent=x;return root
fn rbtu_insert(mut t:InlineArray[RBTUNode,RBTU_MAX+1],mut root:Int,z:Int)->Int:
    var y=0;var x=root
    while x!=0:y=x;x=if t[z].key<t[x].key:t[x].left else:t[x].right
    t[z].parent=y
    if y==0:root=z
    elif t[z].key<t[y].key:t[y].left=z
    else:t[y].right=z
    t[z].left=0;t[z].right=0;t[z].red=True
    var cur=z
    while t[t[cur].parent].red:
        let par=t[cur].parent;let grand=t[par].parent
        if par==t[grand].left:
            y=t[grand].right
            if t[y].red:t[par].red=False;t[y].red=False;t[grand].red=True;cur=grand
            else:
                if cur==t[par].right:cur=par;root=rbtu_left(t,root,cur)
                let p=t[cur].parent;let g=t[p].parent;t[p].red=False;t[g].red=True;root=rbtu_right(t,root,g)
        else:
            y=t[grand].left
            if t[y].red:t[par].red=False;t[y].red=False;t[grand].red=True;cur=grand
            else:
                if cur==t[par].left:cur=par;root=rbtu_right(t,root,cur)
                let p=t[cur].parent;let g=t[p].parent;t[p].red=False;t[g].red=True;root=rbtu_left(t,root,g)
    t[root].red=False;return root
fn rbtu_min(t:InlineArray[RBTUNode,RBTU_MAX+1],node0:Int)->Int:
    var node=node0
    while t[node].left!=0:node=t[node].left
    return node
fn rbtu_transplant(mut t:InlineArray[RBTUNode,RBTU_MAX+1],mut root:Int,u:Int,v:Int)->Int:
    let parent=t[u].parent
    if parent==0:root=v
    elif u==t[parent].left:t[parent].left=v
    else:t[parent].right=v
    t[v].parent=parent;return root
fn rbtu_delete_fix(mut t:InlineArray[RBTUNode,RBTU_MAX+1],mut root:Int,x0:Int)->Int:
    var x=x0
    while x!=root and not t[x].red:
        let p=t[x].parent
        if x==t[p].left:
            var w=t[p].right
            if t[w].red:t[w].red=False;t[p].red=True;root=rbtu_left(t,root,p);w=t[t[x].parent].right
            if not t[t[w].left].red and not t[t[w].right].red:t[w].red=True;x=t[x].parent
            else:
                if not t[t[w].right].red:let wl=t[w].left;t[wl].red=False;t[w].red=True;root=rbtu_right(t,root,w);w=t[t[x].parent].right
                let pp=t[x].parent;let wr=t[w].right;t[w].red=t[pp].red;t[pp].red=False;t[wr].red=False;root=rbtu_left(t,root,pp);x=root
        else:
            var w=t[p].left
            if t[w].red:t[w].red=False;t[p].red=True;root=rbtu_right(t,root,p);w=t[t[x].parent].left
            if not t[t[w].right].red and not t[t[w].left].red:t[w].red=True;x=t[x].parent
            else:
                if not t[t[w].left].red:let wr=t[w].right;t[wr].red=False;t[w].red=True;root=rbtu_left(t,root,w);w=t[t[x].parent].left
                let pp=t[x].parent;let wl=t[w].left;t[w].red=t[pp].red;t[pp].red=False;t[wl].red=False;root=rbtu_right(t,root,pp);x=root
    t[x].red=False;return root
fn rbtu_delete(mut t:InlineArray[RBTUNode,RBTU_MAX+1],mut root:Int,z:Int)->Int:
    var y=z;var x=0;var was_red=t[y].red
    if t[z].left==0:x=t[z].right;root=rbtu_transplant(t,root,z,t[z].right)
    elif t[z].right==0:x=t[z].left;root=rbtu_transplant(t,root,z,t[z].left)
    else:
        y=rbtu_min(t,t[z].right);was_red=t[y].red;x=t[y].right
        if t[y].parent==z:t[x].parent=y
        else:
            let yr=t[y].right;root=rbtu_transplant(t,root,y,yr);let zr=t[z].right;t[y].right=zr;t[zr].parent=y
        let zl=t[z].left;let zred=t[z].red;root=rbtu_transplant(t,root,z,y);t[y].left=zl;t[zl].parent=y;t[y].red=zred
    if not was_red:root=rbtu_delete_fix(t,root,x)
    return root
fn rbtu_put(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Int64):
    let b=UInt64(x);for j in range(8):o[at+j]=UInt8((b>>(8*j))&UInt64(255))
@export("red_black_tree_unique_key_ops")
fn red_black_tree_unique_key_ops(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>128 or Int(n)!=1+2*Int(v[0]):return -1
    let ops=Int(v[0]);var active=InlineArray[Int64,128](fill=0);var active_count=0;var search_count=0
    for i in range(ops):
        let op=v[1+2*i];let key=v[2+2*i]
        if op<0 or op>2 or key< -2147483648 or key>2147483647:return -1
        var pos=0;while pos<active_count and active[pos]!=key:pos+=1
        if op==0:if pos<active_count or active_count>=128:return -1;active[active_count]=key;active_count+=1
        elif op==1:search_count+=1
        else:if pos==active_count:return -1;for j in range(pos,active_count-1):active[j]=active[j+1];active_count-=1
    var t=InlineArray[RBTUNode,RBTU_MAX+1](fill=RBTUNode(key=0,left=0,right=0,parent=0,red=False));var root=0;var next=1;var results=InlineArray[Int64,128](fill=0);var nr=0
    for i in range(ops):
        let op=v[1+2*i];let key=v[2+2*i]
        if op==0:t[next].key=key;root=rbtu_insert(t,root,next);next+=1
        elif op==1:results[nr]=if rbtu_find(t,root,key)!=0:1 else:0;nr+=1
        else:root=rbtu_delete(t,root,rbtu_find(t,root,key))
    let bytes=8*(2+active_count+search_count)
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    rbtu_put(o,0,Int64(active_count));var stack=InlineArray[Int64,128](fill=0);var top=0;var cur=root;var out=1
    while cur!=0 or top>0:
        while cur!=0:stack[top]=Int64(cur);top+=1;cur=t[cur].left
        top-=1;cur=Int(stack[top]);rbtu_put(o,8*out,t[cur].key);out+=1;cur=t[cur].right
    rbtu_put(o,8*out,Int64(search_count));out+=1
    for i in range(search_count):rbtu_put(o,8*out,results[i]);out+=1
    return Int64(bytes)
