from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn treap_pri(key:Int64)->Int64:return ((key+1000000)*1103515245+12345)%2147483648
fn treap_contains(keys:InlineArray[Int64,129],left:InlineArray[Int,129],right:InlineArray[Int,129],root:Int,key:Int64)->Bool:
    var n=root
    while n!=0:
        if keys[n]==key:return True
        n=if key<keys[n] then left[n] else right[n]
    return False
fn treap_rot_right(inout left:InlineArray[Int,129],inout right:InlineArray[Int,129],root:Int)->Int:
    let p=left[root];left[root]=right[p];right[p]=root;return p
fn treap_rot_left(inout left:InlineArray[Int,129],inout right:InlineArray[Int,129],root:Int)->Int:
    let p=right[root];right[root]=left[p];left[p]=root;return p
fn treap_insert(inout keys:InlineArray[Int64,129],inout pri:InlineArray[Int64,129],inout left:InlineArray[Int,129],inout right:InlineArray[Int,129],inout next:Int,root:Int,key:Int64)->Int:
    if root==0:
        let id=next;next+=1;keys[id]=key;pri[id]=treap_pri(key);left[id]=0;right[id]=0;return id
    if key==keys[root]:return root
    if key<keys[root]:
        left[root]=treap_insert(keys,pri,left,right,next,left[root],key)
        if pri[left[root]]>pri[root]:return treap_rot_right(left,right,root)
    else:
        right[root]=treap_insert(keys,pri,left,right,next,right[root],key)
        if pri[right[root]]>pri[root]:return treap_rot_left(left,right,root)
    return root
fn treap_merge(pri:InlineArray[Int64,129],inout left:InlineArray[Int,129],inout right:InlineArray[Int,129],l:Int,r:Int)->Int:
    if l==0:return r
    if r==0:return l
    if pri[l]>pri[r]:right[l]=treap_merge(pri,left,right,right[l],r);return l
    left[r]=treap_merge(pri,left,right,l,left[r]);return r
fn treap_erase(keys:InlineArray[Int64,129],pri:InlineArray[Int64,129],inout left:InlineArray[Int,129],inout right:InlineArray[Int,129],root:Int,key:Int64)->Int:
    if key<keys[root]:left[root]=treap_erase(keys,pri,left,right,left[root],key)
    elif key>keys[root]:right[root]=treap_erase(keys,pri,left,right,right[root],key)
    else:return treap_merge(pri,left,right,left[root],right[root])
    return root
@export("treap_unique_key_set")
fn treap_unique_key_set(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257 or a[0]<0 or a[0]>128 or n!=c_size_t(1+2*a[0]):return -1
    let ops=Int(a[0])
    for i in range(ops):
        let op=a[1+2*i];let key=a[2+2*i]
        if (op!=0 and op!=1) or key< -1000000 or key>1000000:return -1
    var keys=InlineArray[Int64,129]();var pri=InlineArray[Int64,129]();var left=InlineArray[Int,129]();var right=InlineArray[Int,129]();var next=1;var root=0
    for i in range(ops):
        let op=a[1+2*i];let key=a[2+2*i];let present=treap_contains(keys,left,right,root,key)
        if (op==0 and present) or (op==1 and not present):return -1
        if op==0:root=treap_insert(keys,pri,left,right,next,root,key)
        else:root=treap_erase(keys,pri,left,right,root,key)
    var stack=InlineArray[Int,128]();var sorted=InlineArray[Int64,128]();var top=0;var cur=root;var count=0
    while cur!=0 or top>0:
        while cur!=0:stack[top]=cur;top+=1;cur=left[cur]
        top-=1;cur=stack[top];sorted[count]=keys[cur];count+=1;cur=right[cur]
    let bytes=count*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(count):
        let bits=UInt64(sorted[i])
        for b in range(8):o[i*8+b]=UInt8((bits>>(8*b))&255)
    return Int64(count)
