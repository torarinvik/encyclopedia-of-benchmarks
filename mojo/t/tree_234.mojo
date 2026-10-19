from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn t234_new(inout keys:InlineArray[Int64,6147],inout child:InlineArray[Int,8196],inout counts:InlineArray[Int,2049],inout leaf:InlineArray[Bool,2049],inout nodes:Int,isleaf:Bool)->Int:
    let id=nodes;nodes+=1;counts[id]=0;leaf[id]=isleaf
    for j in range(4):child[id*4+j]= -1
    return id
fn t234_contains(keys:InlineArray[Int64,6147],child:InlineArray[Int,8196],counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],root:Int,key:Int64)->Bool:
    var node=root
    while node>=0:
        var slot=0
        while slot<counts[node] and key>keys[node*3+slot]:slot+=1
        if slot<counts[node] and key==keys[node*3+slot]:return True
        if leaf[node]:return False
        node=child[node*4+slot]
    return False
fn t234_split(inout keys:InlineArray[Int64,6147],inout child:InlineArray[Int,8196],inout counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],inout nodes:Int,parent:Int,slot:Int):
    let ch=child[parent*4+slot];let r=t234_new(keys,child,counts,leaf,nodes,leaf[ch]);keys[r*3]=keys[ch*3+2];counts[r]=1
    if not leaf[ch]:child[r*4]=child[ch*4+2];child[r*4+1]=child[ch*4+3]
    let middle=keys[ch*3+1];counts[ch]=1;let pc=counts[parent]
    for i in range(pc-slot):let j=pc-i;keys[parent*3+j]=keys[parent*3+j-1]
    for i in range(pc-slot+1):let j=pc+1-i;child[parent*4+j]=child[parent*4+j-1]
    keys[parent*3+slot]=middle;child[parent*4+slot+1]=r;counts[parent]+=1
fn t234_insert_nonfull(inout keys:InlineArray[Int64,6147],inout child:InlineArray[Int,8196],inout counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],inout nodes:Int,node:Int,key:Int64):
    var slot=counts[node]
    if leaf[node]:
        while slot>0 and key<keys[node*3+slot-1]:keys[node*3+slot]=keys[node*3+slot-1];slot-=1
        keys[node*3+slot]=key;counts[node]+=1;return
    while slot>0 and key<keys[node*3+slot-1]:slot-=1
    var ch=child[node*4+slot]
    if counts[ch]==3:
        t234_split(keys,child,counts,leaf,nodes,node,slot)
        if key>keys[node*3+slot]:slot+=1
        ch=child[node*4+slot]
    t234_insert_nonfull(keys,child,counts,leaf,nodes,ch,key)
fn t234_insert(inout keys:InlineArray[Int64,6147],inout child:InlineArray[Int,8196],inout counts:InlineArray[Int,2049],inout leaf:InlineArray[Bool,2049],inout nodes:Int,inout root:Int,key:Int64):
    if t234_contains(keys,child,counts,leaf,root,key):return
    if root<0:
        root=t234_new(keys,child,counts,leaf,nodes,True);keys[root*3]=key;counts[root]=1;return
    if counts[root]==3:
        let newroot=t234_new(keys,child,counts,leaf,nodes,False);child[newroot*4]=root;root=newroot;t234_split(keys,child,counts,leaf,nodes,root,0)
    t234_insert_nonfull(keys,child,counts,leaf,nodes,root,key)
fn t234_pred(keys:InlineArray[Int64,6147],child:InlineArray[Int,8196],counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],node0:Int)->Int64:
    var node=node0
    while not leaf[node]:node=child[node*4+counts[node]]
    return keys[node*3+counts[node]-1]
fn t234_succ(keys:InlineArray[Int64,6147],child:InlineArray[Int,8196],leaf:InlineArray[Bool,2049],node0:Int)->Int64:
    var node=node0
    while not leaf[node]:node=child[node*4]
    return keys[node*3]
fn t234_merge(inout keys:InlineArray[Int64,6147],inout child:InlineArray[Int,8196],inout counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],parent:Int,slot:Int)->Int:
    let l=child[parent*4+slot];let r=child[parent*4+slot+1];let lc=counts[l];let rc=counts[r]
    keys[l*3+lc]=keys[parent*3+slot]
    for i in range(rc):keys[l*3+lc+1+i]=keys[r*3+i]
    if not leaf[l]:
        for i in range(rc+1):child[l*4+lc+1+i]=child[r*4+i]
    counts[l]=lc+1+rc;let pc=counts[parent]
    for i in range(slot,pc-1):keys[parent*3+i]=keys[parent*3+i+1]
    for i in range(slot+1,pc):child[parent*4+i]=child[parent*4+i+1]
    counts[parent]-=1
    return l
fn t234_borrow_prev(inout keys:InlineArray[Int64,6147],inout child:InlineArray[Int,8196],inout counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],parent:Int,slot:Int):
    let c=child[parent*4+slot];let s=child[parent*4+slot-1];let cc=counts[c];let sc=counts[s]
    for i in range(cc):let j=cc-i;keys[c*3+j]=keys[c*3+j-1]
    if not leaf[c]:
        for i in range(cc+1):let j=cc+1-i;child[c*4+j]=child[c*4+j-1]
        child[c*4]=child[s*4+sc]
    keys[c*3]=keys[parent*3+slot-1];keys[parent*3+slot-1]=keys[s*3+sc-1];counts[c]+=1;counts[s]-=1
fn t234_borrow_next(inout keys:InlineArray[Int64,6147],inout child:InlineArray[Int,8196],inout counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],parent:Int,slot:Int):
    let c=child[parent*4+slot];let s=child[parent*4+slot+1];let cc=counts[c];let sc=counts[s]
    keys[c*3+cc]=keys[parent*3+slot]
    if not leaf[c]:child[c*4+cc+1]=child[s*4]
    keys[parent*3+slot]=keys[s*3]
    for i in range(sc-1):keys[s*3+i]=keys[s*3+i+1]
    if not leaf[s]:
        for i in range(sc):child[s*4+i]=child[s*4+i+1]
    counts[c]+=1;counts[s]-=1
fn t234_delete_node(inout keys:InlineArray[Int64,6147],inout child:InlineArray[Int,8196],inout counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],node:Int,key:Int64):
    var slot=0
    while slot<counts[node] and keys[node*3+slot]<key:slot+=1
    let found=slot<counts[node] and keys[node*3+slot]==key
    if found:
        if leaf[node]:
            for i in range(slot,counts[node]-1):keys[node*3+i]=keys[node*3+i+1]
            counts[node]-=1;return
        let l=child[node*4+slot];let r=child[node*4+slot+1]
        if counts[l]>=2:
            let replacement=t234_pred(keys,child,counts,leaf,l);keys[node*3+slot]=replacement;t234_delete_node(keys,child,counts,leaf,l,replacement)
        elif counts[r]>=2:
            let replacement=t234_succ(keys,child,leaf,r);keys[node*3+slot]=replacement;t234_delete_node(keys,child,counts,leaf,r,replacement)
        else:
            let merged=t234_merge(keys,child,counts,leaf,node,slot);t234_delete_node(keys,child,counts,leaf,merged,key)
        return
    if leaf[node]:return
    var chslot=slot;var ch=child[node*4+chslot]
    if counts[ch]==1:
        if chslot>0 and counts[child[node*4+chslot-1]]>=2:t234_borrow_prev(keys,child,counts,leaf,node,chslot)
        elif chslot<counts[node] and counts[child[node*4+chslot+1]]>=2:t234_borrow_next(keys,child,counts,leaf,node,chslot)
        elif chslot<counts[node]:ch=t234_merge(keys,child,counts,leaf,node,chslot)
        else:chslot-=1;ch=t234_merge(keys,child,counts,leaf,node,chslot)
    t234_delete_node(keys,child,counts,leaf,ch,key)
fn t234_walk(keys:InlineArray[Int64,6147],child:InlineArray[Int,8196],counts:InlineArray[Int,2049],leaf:InlineArray[Bool,2049],node:Int,inout out:InlineArray[Int64,128],inout size:Int):
    if node<0:return
    for i in range(counts[node]):
        if not leaf[node]:t234_walk(keys,child,counts,leaf,child[node*4+i],out,size)
        out[size]=keys[node*3+i];size+=1
    if not leaf[node]:t234_walk(keys,child,counts,leaf,child[node*4+counts[node]],out,size)
@export("tree_234")
fn tree_234(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>258 or a[0]<0 or a[0]>128 or n!=c_size_t(1+2*a[0]):return -1
    let ops=Int(a[0])
    for i in range(ops):
        if a[1+2*i]!=0 and a[1+2*i]!=1:return -1
    var keys=InlineArray[Int64,6147]();var child=InlineArray[Int,8196](-1);var counts=InlineArray[Int,2049]();var leaf=InlineArray[Bool,2049]();var nodes=0;var root= -1
    var remove_results=InlineArray[Int64,128]();var removed=0
    for i in range(ops):
        let op=a[1+2*i];let key=a[2+2*i]
        if op==0:t234_insert(keys,child,counts,leaf,nodes,root,key)
        else:
            let present=t234_contains(keys,child,counts,leaf,root,key)
            remove_results[removed]=1 if present else 0;removed+=1
            if present:
                t234_delete_node(keys,child,counts,leaf,root,key)
                if counts[root]==0:root=if leaf[root] then -1 else child[root*4]
    var sorted=InlineArray[Int64,128]();var size=0;t234_walk(keys,child,counts,leaf,root,sorted,size)
    let words=2+removed+size;let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var staged=InlineArray[Int64,130]();staged[0]=Int64(removed)
    for i in range(removed):staged[1+i]=remove_results[i]
    staged[1+removed]=Int64(size)
    for i in range(size):staged[2+removed+i]=sorted[i]
    for i in range(words):
        let bits=UInt64(staged[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return Int64(bytes)
