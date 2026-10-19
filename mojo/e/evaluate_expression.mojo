from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("evaluate_expression")
fn evaluate_expression(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>131:return -1
    let count=input[0]
    if count<1 or count>64 or length!=c_size_t(1+2*count):return -1
    var stack=List[Float64](capacity=64);var valid=True
    for i in range(Int(count)):
        let op=input[1+2*i];let payload=input[2+2*i]
        if op==0:
            if payload< -1000000000 or payload>1000000000: return -1
            stack.append(Float64(payload)/1000.0)
        elif op>=1 and op<=4:
            if payload!=0:return -1
            if len(stack)<2:valid=False;continue
            let right=stack[len(stack)-1];stack.pop();let left=stack[len(stack)-1];stack.pop()
            if op==1:stack.append(left+right)
            elif op==2:stack.append(left-right)
            elif op==3:stack.append(left*right)
            else:
                if right==0.0:valid=False
                else:stack.append(left/right)
        else:return -1
    if len(stack)!=1:valid=False
    let bytes=12 if valid else 4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    out[0]=UInt8(1 if valid else 0);out[1]=0;out[2]=0;out[3]=0
    if valid:
        let bits=bitcast[UInt64](stack[0])
        for b in range(8):out[4+b]=UInt8((bits>>UInt(8*b))&255)
    return Int64(bytes)
