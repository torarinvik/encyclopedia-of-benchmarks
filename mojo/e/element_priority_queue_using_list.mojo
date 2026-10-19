from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn epq_store(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)

@export("element_priority_queue_using_list")
fn element_priority_queue_using_list(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>514:return -1
    let count=input[0]
    if count<0 or count>256 or length!=c_size_t(1+2*count):return -1
    var queue=List[Int64](capacity=100);var dequeued=List[Int64](capacity=128)
    for i in range(Int(count)):
        let opcode=input[1+2*i];let arg=input[2+2*i]
        if opcode==0:
            if arg< -2147483648 or arg>2147483647 or len(queue)>=100:return -1
            queue.append(arg)
        elif opcode==1:
            if arg!=0 or len(queue)==0:return -1
            var best=0
            for j in range(1,len(queue)):if queue[j]<queue[best]:best=j
            dequeued.append(queue[best])
            for j in range(best,len(queue)-1):queue[j]=queue[j+1]
            queue.pop()
        else:return -1
    let bytes=len(dequeued)*8
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(len(dequeued)):epq_store(output,i*8,dequeued[i])
    return Int64(bytes)
