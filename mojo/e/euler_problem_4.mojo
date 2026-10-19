from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn euler_is_palindrome(value:Int)->Bool:
    var n=value;var reversed=0
    while n>0:reversed=reversed*10+n%10;n//=10
    return n==0 and reversed==value
@export("euler_problem_4")
fn euler_problem_4(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1:return -1
    let digits=input[0];if digits<1 or digits>3:return -1
    let low=1 if digits==1 else (100 if digits==3 else 10);let high=9 if digits==1 else (999 if digits==3 else 99)
    var best=0
    for a in range(low,high+1):
        for b in range(a,high+1):
            let value=a*b
            if value>best and euler_is_palindrome(value):best=value
    return best
