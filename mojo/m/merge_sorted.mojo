from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("merge_sorted")
fn merge_sorted(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>131:return -1
    let a=v[0];let b=v[1]
    if a<0 or b<0 or a>64 or b>64 or Int(n)!=Int(a+b)+2:return -1
    let bs=Int(a)+2
    for i in range(Int(a)):
        if v[i+2] < -1000000 or v[i+2] > 1000000 or (i>0 and v[i+1]>v[i+2]):return -1
    for i in range(Int(b)):
        if v[bs+i] < -1000000 or v[bs+i] > 1000000 or (i>0 and v[bs+i-1]>v[bs+i]):return -1
    var i=0;var j=0;var outi=0;var sum:Int64=0
    while i<Int(a) and j<Int(b):
        let x=if v[2+i]<=v[bs+j]:v[2+i] else:v[bs+j]
        if v[2+i]<=v[bs+j]:i+=1
        else:j+=1
        sum+=Int64(outi+1)*(x+1000001);outi+=1
    while i<Int(a):sum+=Int64(outi+1)*(v[2+i]+1000001);outi+=1;i+=1
    while j<Int(b):sum+=Int64(outi+1)*(v[bs+j]+1000001);outi+=1;j+=1
    return sum
