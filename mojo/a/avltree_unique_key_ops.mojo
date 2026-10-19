from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn unique_height(root:Int, left:List[Int], right:List[Int])->Int:
    if root<0: return 0
    return 1+max(unique_height(left[root],left,right),unique_height(right[root],left,right))
fn unique_update(root:Int, mut height:List[Int], left:List[Int], right:List[Int]):
    height[root]=1+max(unique_height(left[root],left,right),unique_height(right[root],left,right))
fn unique_rr(root:Int, mut height:List[Int], mut left:List[Int], mut right:List[Int])->Int:
    let p=left[root]; let mid=right[p]; right[p]=root; left[root]=mid
    unique_update(root,height,left,right); unique_update(p,height,left,right); return p
fn unique_rl(root:Int, mut height:List[Int], mut left:List[Int], mut right:List[Int])->Int:
    let p=right[root]; let mid=left[p]; left[p]=root; right[root]=mid
    unique_update(root,height,left,right); unique_update(p,height,left,right); return p
fn unique_rebalance(root0:Int, mut height:List[Int], mut left:List[Int], mut right:List[Int])->Int:
    if root0<0: return root0
    var root=root0
    unique_update(root,height,left,right)
    let balance=unique_height(left[root],left,right)-unique_height(right[root],left,right)
    if balance>1:
        if unique_height(right[left[root]],left,right)>unique_height(left[left[root]],left,right): left[root]=unique_rl(left[root],height,left,right)
        return unique_rr(root,height,left,right)
    if balance < -1:
        if unique_height(left[right[root]],left,right)>unique_height(right[right[root]],left,right): right[root]=unique_rr(right[root],height,left,right)
        return unique_rl(root,height,left,right)
    return root
fn unique_insert(root:Int,key:Int64,mut keys:List[Int64],mut height:List[Int],mut left:List[Int],mut right:List[Int],mut next:Int)->Int:
    if root<0:
        let node=next; next+=1; keys[node]=key; left[node]=-1; right[node]=-1; height[node]=1; return node
    if key<keys[root]: left[root]=unique_insert(left[root],key,keys,height,left,right,next)
    else: right[root]=unique_insert(right[root],key,keys,height,left,right,next)
    return unique_rebalance(root,height,left,right)
fn unique_find(root0:Int,key:Int64,keys:List[Int64],left:List[Int],right:List[Int])->Int:
    var root=root0
    while root>=0:
        if keys[root]==key:return root
        if key<keys[root]:root=left[root]
        else:root=right[root]
    return -1
fn unique_maximum(root0:Int,left:List[Int],right:List[Int])->Int:
    var root=root0
    while right[root]>=0:root=right[root]
    return root
fn unique_delete(root0:Int,key:Int64,mut keys:List[Int64],mut height:List[Int],mut left:List[Int],mut right:List[Int])->Int:
    var root=root0
    if key<keys[root]: left[root]=unique_delete(left[root],key,keys,height,left,right)
    elif key>keys[root]: right[root]=unique_delete(right[root],key,keys,height,left,right)
    else:
        if left[root]<0:return right[root]
        if right[root]<0:return left[root]
        let predecessor=unique_maximum(left[root],left,right)
        keys[root]=keys[predecessor]
        left[root]=unique_delete(left[root],keys[predecessor],keys,height,left,right)
    return unique_rebalance(root,height,left,right)
fn unique_put(output:UnsafePointer[UInt8,MutAnyOrigin],word:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):output[word*8+b]=UInt8((bits>>UInt(8*b))&255)

@export("avltree_unique_key_ops")
fn avltree_unique_key_ops(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or input[0]<0 or input[0]>128 or length!=c_size_t(1+2*input[0]):return -1
    let ops=Int(input[0]);var active=List[Int64](capacity=128);var searches=List[Int64](capacity=128)
    for i in range(ops):
        let op=input[1+2*i];let key=input[2+2*i]
        if op<0 or op>2 or key < -1000000 or key>1000000:return -1
        var found=False
        for j in range(len(active)):
            if active[j]==key:found=True
        if op==0:
            if found or len(active)>=128:return -1
            active.append(key)
        elif op==1: searches.append(key)
        else:
            if not found:return -1
            for j in range(len(active)):
                if active[j]==key:
                    for k in range(j,len(active)-1):active[k]=active[k+1]
                    active.pop();break
    var keys=List[Int64](length=128,fill=0);var heights=List[Int](length=128,fill=0)
    var left=List[Int](length=128,fill=-1);var right=List[Int](length=128,fill=-1);var next=0;var root=-1
    var results=List[Int64](capacity=128)
    for i in range(ops):
        let op=input[1+2*i];let key=input[2+2*i]
        if op==0:root=unique_insert(root,key,keys,heights,left,right,next)
        elif op==1:
            if unique_find(root,key,keys,left,right)>=0:results.append(1)
            else:results.append(0)
        else:root=unique_delete(root,key,keys,heights,left,right)
    for i in range(1,len(active)):
        let value=active[i];var j=i
        while j>0 and active[j-1]>value:active[j]=active[j-1];j-=1
        active[j]=value
    let words=2+len(active)+len(results);let bytes=words*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    unique_put(output,0,Int64(len(active)))
    for i in range(len(active)):unique_put(output,i+1,active[i])
    unique_put(output,1+len(active),Int64(len(results)))
    for i in range(len(results)):unique_put(output,2+len(active)+i,results[i])
    return Int64(bytes)
