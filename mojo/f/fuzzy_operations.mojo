from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn fuzzy_put(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[at+b]=UInt8((bits>>(8*b))&255)

@export("fuzzy_operations")
fn fuzzy_operations(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                    output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=8:return -1
    let op=input[0]
    if op<0 or op>3:return -1
    for i in range(1,8):
        if input[i]<0 or input[i]>1000:return -1
    if op==0:
        for i in range(4,8):
            if input[i]!=0:return -1
    elif op==1 or op==2:
        if input[7]!=0:return -1
    else:
        if input[4]!=0 or input[5]!=0 or input[6]!=0 or not (input[1]<input[2] and input[2]<input[3]):return -1
    let count=3 if op<3 else 1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(count*8):return -2
    let a=Float64(input[1])/1000.0;let b=Float64(input[2])/1000.0;let c=Float64(input[3])/1000.0
    if op==0:
        fuzzy_put(output,0,1.0-c);fuzzy_put(output,8,1.0-a);fuzzy_put(output,16,1.0-b)
    elif op==1:
        let d=Float64(input[4])/1000.0;let e=Float64(input[5])/1000.0;let f=Float64(input[6])/1000.0
        fuzzy_put(output,0,a if a>d else d);fuzzy_put(output,8,c if c<f else f);fuzzy_put(output,16,(b+e)/2.0)
    elif op==2:
        let d=Float64(input[4])/1000.0;let e=Float64(input[5])/1000.0;let f=Float64(input[6])/1000.0
        fuzzy_put(output,0,a if a<d else d);fuzzy_put(output,8,(b+e)/2.0);fuzzy_put(output,16,c if c>f else f)
    else:
        let x=Float64(input[7])/1000.0
        var y=0.0
        if x>a and x<c:y=(x-a)/(b-a) if x<=b else (c-x)/(c-b)
        fuzzy_put(output,0,y)
    return Int64(count*8)
