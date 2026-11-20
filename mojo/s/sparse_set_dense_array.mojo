from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_UNIVERSE = 32
const MAX_OPERATIONS = 30
const MAX_LENGTH = 63

@export("sparse_set_dense_array")
fn sparse_set_dense_array(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>MAX_LENGTH: return -1
    if input[0]<1 or input[0]>MAX_UNIVERSE or input[1]<0 or input[1]>MAX_OPERATIONS: return -1
    let universe=Int(input[0])
    let count=Int(input[1])
    if length!=c_size_t(2+2*count): return -1
    for i in range(count):
        let opcode=input[2+2*i]
        let key=input[3+2*i]
        if opcode<0 or opcode>3 or key<0 or key>=input[0]: return -1
        if opcode==3 and key!=0: return -1

    var dense=InlineArray[Int,MAX_UNIVERSE](fill=0)
    var sparse=InlineArray[Int,MAX_UNIVERSE](fill=universe)
    var size=0
    var answers:Int64=0
    for i in range(count):
        let opcode=Int(input[2+2*i])
        let key=Int(input[3+2*i])
        let index=sparse[key]
        let present=index<size and dense[index]==key
        var status:Int64=0
        if opcode==0:
            if not present:
                dense[size]=key
                sparse[key]=size
                size+=1
                status=1
        elif opcode==1:
            if present:
                let last=dense[size-1]
                dense[index]=last
                sparse[last]=index
                size-=1
                status=1
        elif opcode==2:
            if present: status=1
        else:
            if size!=0: status=1
            size=0
        answers=(answers<<1)|status
    var final_mask:Int64=0
    for i in range(size): final_mask|=Int64(1)<<dense[i]
    return (final_mask<<count)|answers
