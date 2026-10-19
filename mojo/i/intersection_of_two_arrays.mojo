from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn ita_store(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,value:Int64):
    let bits=UInt32(Int32(value))
    for b in range(4):out[at+b]=UInt8((bits>>(8*b))&255)

@export("intersection_of_two_arrays")
fn intersection_of_two_arrays(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                              output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>130:return -1
    let n1v=input[0]
    if n1v<0 or n1v>64:return -1
    let n1=Int(n1v);let p2=1+n1
    if p2>=Int(length):return -1
    let n2v=input[p2]
    if n2v<0 or n2v>64:return -1
    let n2=Int(n2v);let start2=p2+1
    if n2!=Int(length)-start2:return -1
    for i in range(n1):
        let x=input[1+i]
        if x< -2147483648 or x>2147483647 or (i>0 and input[i]>x):return -1
    for i in range(n2):
        let x=input[start2+i]
        if x< -2147483648 or x>2147483647 or (i>0 and input[start2+i-1]>x):return -1
    let maxres=min(n1,n2)
    if capacity<c_size_t(maxres*4) or (maxres>0 and output==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var i=0;var j=0;var count=0;var previous:Int64=0
    while i<n1 and j<n2:
        let a=input[1+i];let b=input[start2+j]
        if a<b:i+=1
        elif a>b:j+=1
        else:
            if count==0 or a!=previous:ita_store(output,count*4,a);previous=a;count+=1
            i+=1;j+=1
    return Int64(count)
