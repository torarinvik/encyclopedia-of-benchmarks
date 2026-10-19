from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn sp_write(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)

@export("sort_population")
fn sort_population(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>129 or input[0]<1 or input[0]>64:return -1
    let count=Int(input[0])
    if length!=c_size_t(1+2*count):return -1
    var costs=InlineArray[Int64,64](fill=0);var ids=InlineArray[Int64,64](fill=0);var seen=InlineArray[Bool,64](fill=False)
    for i in range(count):
        let cost=input[1+2*i];let id=input[2+2*i]
        if cost< -1000000 or cost>1000000 or id<0 or id>=count:return -1
        if seen[Int(id)]:return -1
        seen[Int(id)]=True;costs[i]=cost;ids[i]=id
    for i in range(1,count):
        let key_cost=costs[i];let key_id=ids[i];var j=i
        while j>0 and costs[j-1]>key_cost:costs[j]=costs[j-1];ids[j]=ids[j-1];j-=1
        costs[j]=key_cost;ids[j]=key_id
    for i in range(1,count):if costs[i-1]==costs[i]:return -1
    let needed=count*16
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(needed):return -2
    for i in range(count):sp_write(output,16*i,costs[i]);sp_write(output,16*i+8,ids[i])
    return Int64(needed)
