from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
@export("selectionsortlinkedlist")
fn selectionsortlinkedlist(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>65:return -1
    let count=a[0];if count<1 or count>64 or n!=c_size_t(count+1):return -1
    var v=InlineArray[Int32,64]();var next=InlineArray[Int32,64]();var head=0
    for i in range(Int(count)):
        if a[i+1]< -2147483648 or a[i+1]>2147483647:return -1
        v[i]=Int32(a[i+1]);next[i]=Int32(i+1) if i+1<Int(count) else -1
    var minimum=head;var current=Int(next[minimum]);var previous=minimum;var sorted_tail= -1
    while next[minimum]>=0:
        while current>=0:
            if v[current]<v[minimum]:
                if sorted_tail<0:
                    if previous==minimum:
                        head=current;next[minimum]=next[current];next[current]=Int32(previous);minimum=current;current=Int(next[previous])
                    else:
                        head=current;next[previous]=next[current];next[current]=Int32(minimum);minimum=current;current=Int(next[previous])
                else:
                    next[sorted_tail]=Int32(current);next[previous]=next[current];next[current]=Int32(minimum);minimum=current;current=Int(next[previous])
            else:
                previous=Int(next[previous]);current=Int(next[current])
        sorted_tail=minimum;minimum=Int(next[minimum]);previous=minimum;current=Int(next[minimum])
    let bytes=Int(count)*4;if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var node=head
    for i in range(Int(count)):
        let bits=bitcast[UInt32](v[node]);for b in range(4):o[i*4+b]=UInt8((bits>>UInt(8*b))&255)
        node=Int(next[node])
    return Int64(bytes)
