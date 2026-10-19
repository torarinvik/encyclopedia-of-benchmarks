from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn fw_store(out:UnsafePointer[UInt8,MutAnyOrigin],at:Int,x:Float64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[at+b]=UInt8((bits>>(8*b))&255)

@export("full_wave_rectifier")
fn full_wave_rectifier(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                       output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=5:return -1
    let rf=input[0];let rs=input[1];let rl=input[2];let vm=input[3];let im=input[4]
    if rf<0 or rf>1000000 or rs<0 or rs>1000000 or rl<1 or rl>1000000 or vm< -1000000 or vm>1000000 or im< -1000000 or im>1000000:return -1
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<48:return -2
    let a=Float64(rf);let b=Float64(rs);let c=Float64(rl);let v=Float64(vm);let current=Float64(im)
    fw_store(output,0,v/(a+b+c));fw_store(output,8,2.0*current*0.318);fw_store(output,16,2.0*0.318*v)
    fw_store(output,24,v/c);fw_store(output,32,current*0.707);fw_store(output,40,v*0.707)
    return 48
