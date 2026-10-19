from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn desel_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt(8*b))&255)
@export("double_ended_selection_sort")
fn double_ended_selection_sort(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if length>256 or (length>0 and input==UnsafePointer[Int64,ImmutAnyOrigin]()):return -1
    var work=List[Int64](capacity=256);var lefts=List[Int64](capacity=128);var rights=List[Int64](capacity=128)
    for i in range(Int(length)):work.append(input[i])
    while len(work)>1:
        var mini=0;var maxi=0
        for i in range(1,len(work)):
            if work[i]<work[mini]:mini=i
            if work[i]>work[maxi]:maxi=i
        let minv=work[mini];let maxv=work[maxi];lefts.append(minv);rights.append(maxv)
        for i in range(mini,len(work)-1):work[i]=work[i+1]
        work.pop();var pos=0
        while pos<len(work) and work[pos]!=maxv:pos+=1
        if pos==len(work):return -1
        for i in range(pos,len(work)-1):work[i]=work[i+1]
        work.pop()
    var result=List[Int64](capacity=256)
    for i in range(len(lefts)):result.append(lefts[i])
    for i in range(len(work)):result.append(work[i])
    for i in range(len(rights)):result.append(rights[len(rights)-1-i])
    let bytes=len(result)*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    for i in range(len(result)):desel_put(out,i,result[i])
    return Int64(bytes)
