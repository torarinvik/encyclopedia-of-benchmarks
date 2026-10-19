from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn fso_store(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[at+b]=UInt8((bits>>(8*b))&255)

@export("fuzzy_set_operations")
fn fuzzy_set_operations(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                        output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<8:return -1
    let op=input[0];let n=input[1]
    if op<0 or op>8 or n<1 or n>8 or Int(length)!=5+3*Int(n):return -1
    let l=input[2];let p=input[3];let r=input[4]
    for i in range(5,Int(length)):
        if input[i]<0 or input[i]>1000:return -1
    if op==0:
        if l<0 or p<l or r<p or r>1000:return -1
        for i in range(Int(n)):
            if input[5+Int(n)+i]!=0 or input[5+2*Int(n)+i]!=0:return -1
    else:
        if l!=0 or p!=0 or r!=0:return -1
        for i in range(Int(n)):
            if input[5+i]!=0:return -1
    let bytes=Int(n)*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(Int(n)):
        var z=0.0
        if op==0:
            let x=Float64(input[5+i])/1000.0;let a=Float64(l)/1000.0;let b=Float64(p)/1000.0;let c=Float64(r)/1000.0
            let u=(x-a)/(b-a) if b>a else (0.0 if x<b else 1.0)
            let w=(c-x)/(c-b) if c>b else (0.0 if x>c else 1.0)
            z=u if u<w else w
            if z<0.0:z=0.0
            if z>1.0:z=1.0
        else:
            let a=Float64(input[5+Int(n)+i])/1000.0;let b=Float64(input[5+2*Int(n)+i])/1000.0
            if op==1:z=a if a>b else b
            elif op==2:z=a if a<b else b
            elif op==3:z=1.0-a
            elif op==4:z=a if a<1.0-b else 1.0-b
            elif op==5:z=a+b-a*b
            elif op==6:z=a*b
            elif op==7:z=a+b if a+b<1.0 else 1.0
            else:z=a+b-1.0 if a+b-1.0>0.0 else 0.0
        fso_store(output,i*8,z)
    return Int64(bytes)
