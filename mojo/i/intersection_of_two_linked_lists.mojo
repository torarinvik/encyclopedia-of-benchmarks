from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("intersection_of_two_linked_lists")
fn intersection_of_two_linked_lists(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>2050:return -2
    let a0=input[0];let b0=input[1]
    if a0<0 or a0>1024 or b0<0 or b0>1024 or length!=c_size_t(2+a0+b0):return -2
    let a=Int(a0);let b=Int(b0)
    for i in range(2,Int(length)):
        if input[i]<0 or input[i]>2147483647:return -2
    if a==0 or b==0:return -1
    var i=0;var j=0;var on_a=True;var jon_a=False
    for _ in range(a+b+1):
        let base_i=2 if on_a else 2+a;let len_i=a if on_a else b
        let base_j=2 if jon_a else 2+a;let len_j=a if jon_a else b
        let x=input[base_i+i];let y=input[base_j+j]
        if x==y:return x
        i+=1;j+=1
        let end_i=i==len_i;let end_j=j==len_j
        if end_i and end_j:return -1
        if end_i:on_a=not on_a;i=0
        if end_j:jon_a=not jon_a;j=0
    return -1
