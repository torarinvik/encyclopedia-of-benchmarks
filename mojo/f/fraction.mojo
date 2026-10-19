from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn fraction_gcd(a0:Int64,b0:Int64)->Int64:
    var a=a0;var b=b0
    if a<0:a= -a
    if b<0:b= -b
    while b!=0:
        let r=a%b;a=b;b=r
    return a
fn fraction_put(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,value:Int64):
    let bits=UInt64(value)
    for i in range(8):out[at+i]=UInt8((bits>>(8*i))&255)

@export("fraction")
fn fraction(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
             output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=4:return -1
    let n1=input[0];let d1=input[1];let n2=input[2];let d2=input[3]
    if n1< -10000 or n1>10000 or n2< -10000 or n2>10000 or d1< -1000 or d1>1000 or d2< -1000 or d2>1000 or d1==0 or d2==0:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<16:return -2
    let g=fraction_gcd(d1,d2)
    var numerator=(d2/g)*n1+(d1/g)*n2
    var denominator=(d1/g)*d2
    let reduce=fraction_gcd(numerator,denominator)
    numerator/=reduce;denominator/=reduce
    if denominator<0:numerator= -numerator;denominator= -denominator
    fraction_put(output,0,numerator);fraction_put(output,8,denominator)
    return 16
