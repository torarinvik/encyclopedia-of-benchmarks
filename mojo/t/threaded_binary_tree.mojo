from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("threaded_binary_tree")
fn threaded_binary_tree(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or a[0]<0 or a[0]>128:return -1
    let count=Int(a[0])
    if n!=c_size_t(count+1):return -1
    for i in range(count):
        if a[i+1]< -2147483648 or a[i+1]>2147483647:return -1
    let bytes=count*4
    if (bytes>0 and o==UnsafePointer[UInt8,MutAnyOrigin]()) or cap<c_size_t(bytes):return -2
    var keys=InlineArray[Int32,128]();var left=InlineArray[Int,128]();var right=InlineArray[Int,128]()
    var lt=InlineArray[Bool,128]();var rt=InlineArray[Bool,128]();var root=-1
    for i in range(count):
        let key=Int32(a[i+1]);keys[i]=key;left[i]=-1;right[i]=-1;lt[i]=False;rt[i]=False
        if root<0:root=i;continue
        var cur=root;var parent=-1
        while True:
            parent=cur
            if key<keys[cur]:
                if not lt[cur] and left[cur]!=-1:cur=left[cur]
                else:break
            else:
                if not rt[cur] and right[cur]!=-1:cur=right[cur]
                else:break
        if key<keys[parent]:
            left[i]=left[parent];lt[i]=lt[parent];right[i]=parent;rt[i]=True;left[parent]=i;lt[parent]=False
        else:
            right[i]=right[parent];rt[i]=rt[parent];left[i]=parent;lt[i]=True;right[parent]=i;rt[parent]=False
    var cur=root
    while cur!=-1 and not lt[cur] and left[cur]!=-1:cur=left[cur]
    var written=0
    while cur!=-1:
        let bits=UInt32(keys[cur])
        for b in range(4):o[written+b]=UInt8((bits>>(8*b))&255)
        written+=4
        if rt[cur]:cur=right[cur]
        else:
            cur=right[cur]
            while cur!=-1 and not lt[cur] and left[cur]!=-1:cur=left[cur]
    return Int64(written)
