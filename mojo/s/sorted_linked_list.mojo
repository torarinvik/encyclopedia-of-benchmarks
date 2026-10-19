from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
struct Node:
    var value:Int64
    var next:Int
@export("sorted_linked_list")
fn sorted_linked_list(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>20:return -1
    let countv=v[0]
    if countv<0 or countv>16 or n!=c_size_t(countv+3):return -1
    let count=Int(countv);var vals=InlineArray[Int64,17](fill=0)
    for i in range(count):
        if v[1+i]< -2147483648 or v[1+i]>2147483647 or (i>0 and v[i]>=v[i+1]):return -1
        vals[i]=v[i+1]
    let op=v[count+1];let key=v[count+2]
    if op<0 or op>2 or key< -2147483648 or key>2147483647:return -1
    var staged=InlineArray[Int64,18](fill=0);var words=0
    if op==0:
        var pos=0
        while pos<count and vals[pos]<key:pos+=1
        if pos<count and vals[pos]==key:return -1
        for i in range(count,pos,-1):vals[i]=vals[i-1]
        vals[pos]=key;staged[0]=count+1
        for i in range(count+1):staged[i+1]=vals[i]
        words=count+2
    elif op==1:
        var found=0
        for i in range(count):if vals[i]==key:found=1
        staged[0]=found;words=1
    else:
        var pos=0;while pos<count and vals[pos]!=key:pos+=1
        let deleted=1 if pos<count else 0
        if deleted==1:
            for i in range(pos,count-1):vals[i]=vals[i+1]
        let remaining=count-deleted;staged[0]=deleted;staged[1]=remaining
        for i in range(remaining):staged[2+i]=vals[i]
        words=remaining+2
    let bytes=words*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(words):
        let bits=bitcast[UInt64](staged[i]);for b in range(8):o[i*8+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
