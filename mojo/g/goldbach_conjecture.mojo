from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
fn gold_prime(n:Int64)->Bool:
    if n==2:return True
    if n<2 or n%2==0:return False
    var d:Int64=3
    while d<=n//d:
        if n%d==0:return False
        d+=2
    return True
@export("goldbach_conjecture")
fn goldbach_conjecture(number:Int64,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if number<4 or number>4096 or number%2!=0:return -1
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<8:return -2
    for first in range(number//2+1):
        let second=number-first
        if gold_prime(first) and gold_prime(second):
            for j in range(2):
                let value=UInt32(first if j==0 else second)
                for b in range(4):out[4*j+b]=UInt8((value>>UInt32(8*b))&255)
            return 8
    return -1
