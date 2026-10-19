from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn persistent_height(id:Int, heights:List[Int])->Int:
    if id==0:return -1
    return heights[id]
fn persistent_make(mut next:Int,value:Int,left_id:Int,right_id:Int,mut values:List[Int],mut left:List[Int],mut right:List[Int],mut heights:List[Int])->Int:
    let id=next;next+=1
    values[id]=value;left[id]=left_id;right[id]=right_id
    heights[id]=1+max(persistent_height(left_id,heights),persistent_height(right_id,heights))
    return id
fn persistent_balance(id:Int,left:List[Int],right:List[Int],heights:List[Int])->Int:
    return persistent_height(right[id],heights)-persistent_height(left[id],heights)
fn persistent_rotate_right(mut next:Int,id:Int,mut values:List[Int],mut left:List[Int],mut right:List[Int],mut heights:List[Int])->Int:
    let pivot=left[id]
    let moved=persistent_make(next,values[id],right[pivot],right[id],values,left,right,heights)
    return persistent_make(next,values[pivot],left[pivot],moved,values,left,right,heights)
fn persistent_rotate_left(mut next:Int,id:Int,mut values:List[Int],mut left:List[Int],mut right:List[Int],mut heights:List[Int])->Int:
    let pivot=right[id]
    let moved=persistent_make(next,values[id],left[id],left[pivot],values,left,right,heights)
    return persistent_make(next,values[pivot],moved,right[pivot],values,left,right,heights)
fn persistent_rebalance(mut next:Int,id:Int,mut values:List[Int],mut left:List[Int],mut right:List[Int],mut heights:List[Int])->Int:
    let balance=persistent_balance(id,left,right,heights)
    if balance>1:
        var root=id
        if persistent_balance(right[id],left,right,heights)<0:
            let rotated=persistent_rotate_right(next,right[id],values,left,right,heights)
            root=persistent_make(next,values[id],left[id],rotated,values,left,right,heights)
        return persistent_rotate_left(next,root,values,left,right,heights)
    if balance < -1:
        var root=id
        if persistent_balance(left[id],left,right,heights)>0:
            let rotated=persistent_rotate_left(next,left[id],values,left,right,heights)
            root=persistent_make(next,values[id],rotated,right[id],values,left,right,heights)
        return persistent_rotate_right(next,root,values,left,right,heights)
    return id
fn persistent_insert(mut next:Int,root:Int,value:Int,mut values:List[Int],mut left:List[Int],mut right:List[Int],mut heights:List[Int])->Int:
    if root==0:return persistent_make(next,value,0,0,values,left,right,heights)
    var new_left=left[root];var new_right=right[root]
    if value==values[root]:return root
    if value<values[root]:new_left=persistent_insert(next,left[root],value,values,left,right,heights)
    else:new_right=persistent_insert(next,right[root],value,values,left,right,heights)
    let copied=persistent_make(next,values[root],new_left,new_right,values,left,right,heights)
    return persistent_rebalance(next,copied,values,left,right,heights)
fn persistent_delete_min(mut next:Int,root:Int,mut minimum:Int,mut values:List[Int],mut left:List[Int],mut right:List[Int],mut heights:List[Int])->Int:
    if left[root]==0:
        minimum=values[root]
        return right[root]
    let new_left=persistent_delete_min(next,left[root],minimum,values,left,right,heights)
    let copied=persistent_make(next,values[root],new_left,right[root],values,left,right,heights)
    return persistent_rebalance(next,copied,values,left,right,heights)
fn persistent_delete(mut next:Int,root:Int,value:Int,mut values:List[Int],mut left:List[Int],mut right:List[Int],mut heights:List[Int])->Int:
    if root==0:return 0
    if value<values[root]:
        let child=persistent_delete(next,left[root],value,values,left,right,heights)
        let copied=persistent_make(next,values[root],child,right[root],values,left,right,heights)
        return persistent_rebalance(next,copied,values,left,right,heights)
    if value>values[root]:
        let child=persistent_delete(next,right[root],value,values,left,right,heights)
        let copied=persistent_make(next,values[root],left[root],child,values,left,right,heights)
        return persistent_rebalance(next,copied,values,left,right,heights)
    if left[root]==0:return right[root]
    if right[root]==0:return left[root]
    var successor=0
    let new_right=persistent_delete_min(next,right[root],successor,values,left,right,heights)
    let copied=persistent_make(next,successor,left[root],new_right,values,left,right,heights)
    return persistent_rebalance(next,copied,values,left,right,heights)
fn persistent_put(output:UnsafePointer[UInt8,MutAnyOrigin],word:Int,value:Int64):
    let bits=UInt64(value)
    for b in range(8):output[word*8+b]=UInt8((bits>>UInt(8*b))&255)

@export("avltree_persistent_insert_delete")
fn avltree_persistent_insert_delete(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or input[0]<0 or input[0]>32 or length!=c_size_t(1+3*input[0]):return -1
    let operations=Int(input[0])
    for i in range(operations):
        if input[1+3*i]<0 or input[1+3*i]>Int64(i) or (input[2+3*i]!=0 and input[2+3*i]!=1) or input[3+3*i]<-1000 or input[3+3*i]>1000:return -1
    var values=List[Int](length=8192,fill=0);var left=List[Int](length=8192,fill=0);var right=List[Int](length=8192,fill=0);var heights=List[Int](length=8192,fill=0)
    var roots=List[Int](length=33,fill=0);var next=1
    for i in range(operations):
        let parent_root=roots[Int(input[1+3*i])]
        if input[2+3*i]==0:roots[i+1]=persistent_insert(next,parent_root,Int(input[3+3*i]),values,left,right,heights)
        else:roots[i+1]=persistent_delete(next,parent_root,Int(input[3+3*i]),values,left,right,heights)
        if next>=8192-64:return -1
    var encoded=List[Int64](capacity=5000)
    encoded.append(Int64(operations+1))
    for version in range(operations+1):
        let root=roots[version]
        var queue=List[Int](capacity=33)
        var local=List[Int](length=8192,fill=-1)
        if root!=0:
            queue.append(root);local[root]=0
        var head=0
        while head<len(queue):
            let node=queue[head];head+=1
            if left[node]!=0 and local[left[node]]<0:
                local[left[node]]=len(queue);queue.append(left[node])
            if right[node]!=0 and local[right[node]]<0:
                local[right[node]]=len(queue);queue.append(right[node])
        encoded.append(Int64(len(queue)))
        encoded.append(Int64(persistent_height(root,heights)))
        for i in range(len(queue)):
            let node=queue[i]
            var local_left:Int64=-1;var local_right:Int64=-1
            if left[node]!=0:local_left=Int64(local[left[node]])
            if right[node]!=0:local_right=Int64(local[right[node]])
            encoded.append(Int64(values[node]));encoded.append(Int64(heights[node]));encoded.append(local_left);encoded.append(local_right)
    let bytes=len(encoded)*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(len(encoded)):persistent_put(output,i,encoded[i])
    return Int64(bytes)
