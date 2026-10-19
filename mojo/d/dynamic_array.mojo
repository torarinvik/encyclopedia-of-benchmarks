from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn dynamic_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt(b*8))&255)
@export("dynamic_array")
fn dynamic_array(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>385:return -1
    let opcount=input[0]
    if opcount<0 or opcount>128:return -1
    var first=List[Int64](length=64,fill=0);var second=List[Int64](length=64,fill=0);var queries=List[Int64](capacity=128)
    var active=0;var size=0;var store_capacity=16;var cursor=1
    for opi in range(Int(opcount)):
        if cursor>=Int(length):return -1
        let op=input[cursor];cursor+=1
        if op==0:
            if cursor>=Int(length) or size>=64:return -1
            let value=input[cursor];cursor+=1
            if size==store_capacity:
                if active==0:
                    for i in range(size):second[i]=first[i]
                    active=1
                else:
                    for i in range(size):first[i]=second[i]
                    active=0
                store_capacity*=2
            if active==0:first[size]=value
            else:second[size]=value
            size+=1
        elif op==1:
            if cursor+1>=Int(length):return -1
            let index=input[cursor];let value=input[cursor+1];cursor+=2
            if index<0 or index>=Int64(size):return -1
            if active==0:first[Int(index)]=value
            else:second[Int(index)]=value
        elif op==2:
            if cursor>=Int(length) or len(queries)>=128:return -1
            let index=input[cursor];cursor+=1
            if index<0 or index>=Int64(size):return -1
            queries.append(first[Int(index)] if active==0 else second[Int(index)])
        elif op==3:
            if len(queries)>=128:return -1
            queries.append(Int64(size))
        else:return -1
    if cursor!=Int(length):return -1
    let words=2+len(queries)+size
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(words*8):return -2
    dynamic_put(out,0,Int64(len(queries)))
    for i in range(len(queries)):dynamic_put(out,i+1,queries[i])
    dynamic_put(out,len(queries)+1,Int64(size))
    for i in range(size):dynamic_put(out,len(queries)+2+i,first[i] if active==0 else second[i])
    return Int64(words)
