from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn ruby_avl_h(root: Int, left: List[Int], right: List[Int]) -> Int:
    if root < 0: return 0
    return 1 + max(ruby_avl_h(left[root], left, right), ruby_avl_h(right[root], left, right))

fn ruby_avl_rot_r(root: Int, mut left: List[Int], mut right: List[Int]) -> Int:
    let pivot=left[root]; let moved=right[pivot]
    right[pivot]=root; left[root]=moved
    return pivot

fn ruby_avl_rot_l(root: Int, mut left: List[Int], mut right: List[Int]) -> Int:
    let pivot=right[root]; let moved=left[pivot]
    left[pivot]=root; right[root]=moved
    return pivot

fn ruby_avl_insert(root: Int, key: Int64, mut keys: List[Int64], mut left: List[Int], mut right: List[Int], mut next: Int) -> Int:
    if root < 0:
        let node=next; next += 1; keys[node]=key; left[node]=-1; right[node]=-1; return node
    if key < keys[root]: left[root]=ruby_avl_insert(left[root],key,keys,left,right,next)
    else: right[root]=ruby_avl_insert(right[root],key,keys,left,right,next)
    let balance=ruby_avl_h(left[root],left,right)-ruby_avl_h(right[root],left,right)
    if balance > 1:
        if key > keys[left[root]]: left[root]=ruby_avl_rot_l(left[root],left,right)
        return ruby_avl_rot_r(root,left,right)
    if balance < -1:
        if key < keys[right[root]]: right[root]=ruby_avl_rot_r(right[root],left,right)
        return ruby_avl_rot_l(root,left,right)
    return root

fn ruby_avl_find(root0: Int, key: Int64, keys: List[Int64], left: List[Int], right: List[Int]) -> Bool:
    var root=root0
    while root >= 0:
        if keys[root] == key: return True
        if key < keys[root]: root=left[root]
        else: root=right[root]
    return False

fn ruby_avl_put(output: UnsafePointer[UInt8, MutAnyOrigin], word: Int, value: Int64):
    let bits=UInt64(value)
    for b in range(8): output[word*8+b]=UInt8((bits >> UInt(8*b)) & 255)

@export("avl_tree_ruby_unique_key_insert_search")
fn avl_tree_ruby_unique_key_insert_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or input[0] < 0 or input[0] > 128 or length != c_size_t(1 + 2 * input[0]): return -1
    let operations=Int(input[0])
    var inserts=List[Int64](capacity=64)
    var searches=List[Int64](capacity=128)
    for i in range(operations):
        let op=input[1+2*i]; let key=input[2+2*i]
        if (op != 0 and op != 1) or key < -1000000 or key > 1000000: return -1
        if op == 0:
            if len(inserts) >= 64: return -1
            for j in range(len(inserts)):
                if inserts[j] == key: return -1
            inserts.append(key)
        else: searches.append(key)
    var keys=List[Int64](length=64,fill=0)
    var left=List[Int](length=64,fill=-1)
    var right=List[Int](length=64,fill=-1)
    var root=-1
    var next=0
    var results=List[Int64](capacity=128)
    for i in range(operations):
        let op=input[1+2*i]; let key=input[2+2*i]
        if op == 0: root=ruby_avl_insert(root,key,keys,left,right,next)
        else:
            if ruby_avl_find(root,key,keys,left,right): results.append(1)
            else: results.append(0)
    let words=2+len(inserts)+len(results)
    let bytes=words*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    ruby_avl_put(output,0,Int64(len(inserts)))
    var ordered=List[Int64](capacity=64)
    for i in range(len(inserts)): ordered.append(inserts[i])
    for i in range(1,len(ordered)):
        let value=ordered[i]; var j=i
        while j>0 and ordered[j-1]>value:
            ordered[j]=ordered[j-1]; j-=1
        ordered[j]=value
    for i in range(len(ordered)): ruby_avl_put(output,i+1,ordered[i])
    ruby_avl_put(output,1+len(ordered),Int64(len(results)))
    for i in range(len(results)): ruby_avl_put(output,2+len(ordered)+i,results[i])
    return Int64(bytes)
