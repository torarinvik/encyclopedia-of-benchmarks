from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

fn butterfly_write_run(output:UnsafePointer[UInt8,MutAnyOrigin],position:Int,value:UInt8,count:Int)->Int:
    for i in range(count):output[position+i]=value
    return position+count

@export("butterfly_pattern")
fn butterfly_pattern(n:Int64,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if n<1 or n>45:return -1
    let side=Int(n);let width=2*side-1;let required=width*width+2*side-2
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(required):return -2
    var pos=0
    for count in range(1,side):
        if pos!=0:output[pos]=10;pos+=1
        pos=butterfly_write_run(output,pos,42,count)
        pos=butterfly_write_run(output,pos,32,2*(side-count)-1)
        pos=butterfly_write_run(output,pos,42,count)
    if pos!=0:output[pos]=10;pos+=1
    pos=butterfly_write_run(output,pos,42,width)
    for count0 in range(side-1):
        let count=side-1-count0
        output[pos]=10;pos+=1
        pos=butterfly_write_run(output,pos,42,count)
        pos=butterfly_write_run(output,pos,32,2*(side-count)-1)
        pos=butterfly_write_run(output,pos,42,count)
    return Int64(pos)
