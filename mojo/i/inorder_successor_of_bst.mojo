from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("inorder_successor_of_bst")
fn inorder_successor_of_bst(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>67:return -1
    let n=input[0];let target=input[1]
    if n<0 or n>64 or target<1 or target>2147483647 or length!=c_size_t(n+2):return -1
    var keys=InlineArray[Int64,64](fill=0);var left=InlineArray[Int32,64](fill=-1);var right=InlineArray[Int32,64](fill=-1);var root= -1
    for i in range(Int(n)):
        let key=input[i+2]
        if key<1 or key>2147483647:return -1
        for j in range(i):
            if keys[j]==key:return -1
        keys[i]=key
        if root<0:root=i;continue
        var current=root
        while True:
            if key<=keys[current]:
                if left[current]<0:left[current]=Int32(i);break
                current=Int(left[current])
            else:
                if right[current]<0:right[current]=Int32(i);break
                current=Int(right[current])
    var current=root
    while current>=0 and keys[current]!=target:current=Int(right[current]) if target>keys[current] else Int(left[current])
    if current<0:return 0
    if right[current]>=0:
        var successor=Int(right[current])
        while left[successor]>=0:successor=Int(left[successor])
        return keys[successor]
    var successor= -1;var ancestor=root
    while ancestor>=0 and ancestor!=current:
        if keys[current]<keys[ancestor]:successor=ancestor;ancestor=Int(left[ancestor])
        else:ancestor=Int(right[ancestor])
    return 0 if successor<0 else keys[successor]
