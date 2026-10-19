from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime BTREE_T = 255
comptime BTREE_MAX_KEYS = 509
comptime BTREE_MAX_NODES = 32

fn btu_store(o:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):o[offset+b]=UInt8((bits>>UInt(8*b))&255)

fn btu_new_node(inout used:Int,inout counts:InlineArray[Int,32],inout leaves:InlineArray[Bool,32],leaf:Bool)->Int:
    if used>=BTREE_MAX_NODES:return -1
    let result=used;used+=1;counts[result]=0;leaves[result]=leaf;return result

fn btu_search(keys:InlineArray[Int64,16288],children:InlineArray[Int,16320],counts:InlineArray[Int,32],leaves:InlineArray[Bool,32],root:Int,key:Int64)->Bool:
    var node=root
    while true:
        var i=0
        while i<counts[node] and key>keys[node*BTREE_MAX_KEYS+i]:i+=1
        if i<counts[node] and key==keys[node*BTREE_MAX_KEYS+i]:return true
        if leaves[node]:return false
        node=children[node*510+i]
    return false

fn btu_split(inout keys:InlineArray[Int64,16288],inout children:InlineArray[Int,16320],inout counts:InlineArray[Int,32],inout leaves:InlineArray[Bool,32],inout used:Int,parent:Int,index:Int)->Bool:
    let child=children[parent*510+index];let sibling=btu_new_node(used,counts,leaves,leaves[child])
    if sibling<0:return false
    for j in range(BTREE_T-1):keys[sibling*BTREE_MAX_KEYS+j]=keys[child*BTREE_MAX_KEYS+j+BTREE_T]
    if not leaves[child]:
        for j in range(BTREE_T):children[sibling*510+j]=children[child*510+j+BTREE_T]
    counts[sibling]=BTREE_T-1
    let old=counts[parent]
    for j in range(old+1,index+1,-1):children[parent*510+j]=children[parent*510+j-1]
    children[parent*510+index+1]=sibling
    for j in range(old,index,-1):keys[parent*BTREE_MAX_KEYS+j]=keys[parent*BTREE_MAX_KEYS+j-1]
    keys[parent*BTREE_MAX_KEYS+index]=keys[child*BTREE_MAX_KEYS+BTREE_T-1]
    counts[child]=BTREE_T-1;counts[parent]=old+1;return true

fn btu_insert_nonfull(inout keys:InlineArray[Int64,16288],inout children:InlineArray[Int,16320],inout counts:InlineArray[Int,32],inout leaves:InlineArray[Bool,32],inout used:Int,node:Int,key:Int64)->Bool:
    var i=counts[node]-1
    if leaves[node]:
        while i>=0 and key<keys[node*BTREE_MAX_KEYS+i]:keys[node*BTREE_MAX_KEYS+i+1]=keys[node*BTREE_MAX_KEYS+i];i-=1
        keys[node*BTREE_MAX_KEYS+i+1]=key;counts[node]+=1;return true
    while i>=0 and key<keys[node*BTREE_MAX_KEYS+i]:i-=1
    i+=1;var child=children[node*510+i]
    if counts[child]==BTREE_MAX_KEYS:
        if not btu_split(keys,children,counts,leaves,used,node,i):return false
        if key>keys[node*BTREE_MAX_KEYS+i]:i+=1
        child=children[node*510+i]
    return btu_insert_nonfull(keys,children,counts,leaves,used,child,key)

fn btu_predecessor(keys:InlineArray[Int64,16288],children:InlineArray[Int,16320],counts:InlineArray[Int,32],leaves:InlineArray[Bool,32],node0:Int)->Int64:
    var node=node0
    while not leaves[node]:node=children[node*510+counts[node]]
    return keys[node*BTREE_MAX_KEYS+counts[node]-1]
fn btu_successor(keys:InlineArray[Int64,16288],children:InlineArray[Int,16320],leaves:InlineArray[Bool,32],node0:Int)->Int64:
    var node=node0
    while not leaves[node]:node=children[node*510]
    return keys[node*BTREE_MAX_KEYS]

fn btu_merge(inout keys:InlineArray[Int64,16288],inout children:InlineArray[Int,16320],inout counts:InlineArray[Int,32],leaves:InlineArray[Bool,32],parent:Int,index:Int):
    let left=children[parent*510+index];let right=children[parent*510+index+1];var lc=counts[left]
    keys[left*BTREE_MAX_KEYS+lc]=keys[parent*BTREE_MAX_KEYS+index];lc+=1
    for j in range(counts[right]):keys[left*BTREE_MAX_KEYS+lc+j]=keys[right*BTREE_MAX_KEYS+j]
    if not leaves[left]:
        for j in range(counts[right]+1):children[left*510+lc+j]=children[right*510+j]
    counts[left]=lc+counts[right];let pc=counts[parent]
    for j in range(index+1,pc):keys[parent*BTREE_MAX_KEYS+j-1]=keys[parent*BTREE_MAX_KEYS+j]
    for j in range(index+2,pc+1):children[parent*510+j-1]=children[parent*510+j]
    counts[parent]=pc-1

fn btu_borrow_prev(inout keys:InlineArray[Int64,16288],inout children:InlineArray[Int,16320],inout counts:InlineArray[Int,32],leaves:InlineArray[Bool,32],parent:Int,index:Int):
    let child=children[parent*510+index];let sibling=children[parent*510+index-1];let cc=counts[child]
    for j in range(cc,0,-1):keys[child*BTREE_MAX_KEYS+j]=keys[child*BTREE_MAX_KEYS+j-1]
    if not leaves[child]:
        for j in range(cc+1,0,-1):children[child*510+j]=children[child*510+j-1]
    keys[child*BTREE_MAX_KEYS]=keys[parent*BTREE_MAX_KEYS+index-1]
    if not leaves[child]:children[child*510]=children[sibling*510+counts[sibling]]
    keys[parent*BTREE_MAX_KEYS+index-1]=keys[sibling*BTREE_MAX_KEYS+counts[sibling]-1];counts[child]+=1;counts[sibling]-=1
fn btu_borrow_next(inout keys:InlineArray[Int64,16288],inout children:InlineArray[Int,16320],inout counts:InlineArray[Int,32],leaves:InlineArray[Bool,32],parent:Int,index:Int):
    let child=children[parent*510+index];let sibling=children[parent*510+index+1];let cc=counts[child];let sc=counts[sibling]
    keys[child*BTREE_MAX_KEYS+cc]=keys[parent*BTREE_MAX_KEYS+index]
    if not leaves[child]:children[child*510+cc+1]=children[sibling*510]
    keys[parent*BTREE_MAX_KEYS+index]=keys[sibling*BTREE_MAX_KEYS]
    for j in range(1,sc):keys[sibling*BTREE_MAX_KEYS+j-1]=keys[sibling*BTREE_MAX_KEYS+j]
    if not leaves[sibling]:
        for j in range(1,sc+1):children[sibling*510+j-1]=children[sibling*510+j]
    counts[child]+=1;counts[sibling]-=1
fn btu_fill(inout keys:InlineArray[Int64,16288],inout children:InlineArray[Int,16320],inout counts:InlineArray[Int,32],leaves:InlineArray[Bool,32],parent:Int,index:Int):
    if index>0 and counts[children[parent*510+index-1]]>=BTREE_T:btu_borrow_prev(keys,children,counts,leaves,parent,index)
    elif index<counts[parent] and counts[children[parent*510+index+1]]>=BTREE_T:btu_borrow_next(keys,children,counts,leaves,parent,index)
    else:btu_merge(keys,children,counts,leaves,parent,index if index<counts[parent] else index-1)

fn btu_delete_node(inout keys:InlineArray[Int64,16288],inout children:InlineArray[Int,16320],inout counts:InlineArray[Int,32],leaves:InlineArray[Bool,32],node:Int,key:Int64)->Bool:
    var index=0
    while index<counts[node] and keys[node*BTREE_MAX_KEYS+index]<key:index+=1
    if index<counts[node] and keys[node*BTREE_MAX_KEYS+index]==key:
        if leaves[node]:
            for j in range(index+1,counts[node]):keys[node*BTREE_MAX_KEYS+j-1]=keys[node*BTREE_MAX_KEYS+j]
            counts[node]-=1;return true
        let left=children[node*510+index];let right=children[node*510+index+1]
        if counts[left]>=BTREE_T:
            let replacement=btu_predecessor(keys,children,counts,leaves,left);keys[node*BTREE_MAX_KEYS+index]=replacement
            return btu_delete_node(keys,children,counts,leaves,left,replacement)
        if counts[right]>=BTREE_T:
            let replacement=btu_successor(keys,children,leaves,right);keys[node*BTREE_MAX_KEYS+index]=replacement
            return btu_delete_node(keys,children,counts,leaves,right,replacement)
        btu_merge(keys,children,counts,leaves,node,index);return btu_delete_node(keys,children,counts,leaves,left,key)
    if leaves[node]:return false
    let was_last=index==counts[node]
    if counts[children[node*510+index]]<BTREE_T:btu_fill(keys,children,counts,leaves,node,index)
    if was_last and index>counts[node]:index-=1
    return btu_delete_node(keys,children,counts,leaves,children[node*510+index],key)

fn btu_walk(keys:InlineArray[Int64,16288],children:InlineArray[Int,16320],counts:InlineArray[Int,32],leaves:InlineArray[Bool,32],node:Int,inout out:InlineArray[Int64,2048],inout used:Int):
    for i in range(counts[node]):
        if not leaves[node]:btu_walk(keys,children,counts,leaves,children[node*510+i],out,used)
        out[used]=keys[node*BTREE_MAX_KEYS+i];used+=1
    if not leaves[node]:btu_walk(keys,children,counts,leaves,children[node*510+counts[node]],out,used)

@export("btree_unique_key_set")
fn btree_unique_key_set(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>4096:return -1
    let inserts=input[0]
    if inserts<0 or inserts>2048:return -1
    let qoff=1+Int(inserts)
    if qoff>=Int(length) or input[qoff]<0 or input[qoff]>1024:return -1
    let queries=input[qoff];let doff=qoff+1+Int(queries)
    if doff>=Int(length) or input[doff]<0 or input[doff]>1024:return -1
    let deletes=input[doff]
    if length!=c_size_t(3+inserts+queries+deletes):return -1
    var keys=InlineArray[Int64,16288](fill=0);var children=InlineArray[Int,16320](fill=0);var counts=InlineArray[Int,32](fill=0);var leaves=InlineArray[Bool,32](fill=false);var used_nodes=1;var root=0;leaves[0]=true
    for i in range(Int(inserts)):
        let key=input[i+1]
        if key< -2147483648 or key>2147483647 or btu_search(keys,children,counts,leaves,root,key):return -1
        if counts[root]==BTREE_MAX_KEYS:
            let old=root;root=btu_new_node(used_nodes,counts,leaves,false)
            if root<0:return -1
            children[root*510]=old
            if not btu_split(keys,children,counts,leaves,used_nodes,root,0):return -1
        if not btu_insert_nonfull(keys,children,counts,leaves,used_nodes,root,key):return -1
    var staged=InlineArray[Int64,3074](fill=0);staged[0]=queries
    for i in range(Int(queries)):
        let key=input[qoff+1+i];if key< -2147483648 or key>2147483647:return -1
        staged[1+i]=1 if btu_search(keys,children,counts,leaves,root,key) else 0
    for i in range(Int(deletes)):
        let key=input[doff+1+i]
        if key< -2147483648 or key>2147483647 or not btu_search(keys,children,counts,leaves,root,key):return -1
        if not btu_delete_node(keys,children,counts,leaves,root,key):return -1
        if counts[root]==0 and not leaves[root]:root=children[root*510]
    var remaining=InlineArray[Int64,2048](fill=0);var out_count=0;btu_walk(keys,children,counts,leaves,root,remaining,out_count)
    staged[Int(queries)+1]=out_count
    for i in range(out_count):staged[Int(queries)+2+i]=remaining[i]
    let words=Int(queries)+2+out_count;let bytes=words*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(words):btu_store(output,i*8,staged[i])
    return Int64(bytes)
