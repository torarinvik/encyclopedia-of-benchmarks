from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("keys_and_rooms")
fn keys_and_rooms(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>100001 or a[0]<2 or a[0]>1000:return -1
    let rooms=Int(a[0]);var starts=InlineArray[Int64,1000]();var sizes=InlineArray[Int64,1000]();var pos=1
    for r in range(rooms):
        if pos>=Int(n):return -1
        let count=a[pos];pos+=1
        if count<0 or count>rooms or count>Int(n)-pos:return -1
        starts[r]=pos;sizes[r]=count
        for j in range(Int(count)):if a[pos+j]<0 or a[pos+j]>=rooms:return -1
        pos+=Int(count)
    if pos!=Int(n):return -1
    var seen=InlineArray[Bool,1000]();var stack=InlineArray[Int64,1000]();var top=1;var reached=0;stack[0]=0;seen[0]=True
    while top>0:
        top-=1;let r=Int(stack[top]);reached+=1
        for j in range(Int(sizes[r])):
            let key=Int(a[Int(starts[r])+j])
            if not seen[key]:seen[key]=True;stack[top]=key;top+=1
    return 1 if reached==rooms else 0
