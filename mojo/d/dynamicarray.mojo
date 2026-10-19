from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import List
fn dynamicarray_put(out:UnsafePointer[UInt8,MutAnyOrigin],word:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):out[word*8+b]=UInt8((bits>>UInt(b*8))&255)
@export("dynamicarray")
fn dynamicarray(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],capacity_out:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or length>385 or input[0]<0 or input[0]>128:return -1
    var a=List[Int64](length=64,fill=0);var b=List[Int64](length=64,fill=0);var queries=List[Int64](capacity=128)
    var size=0;var data_capacity=0;var cursor=1;var active=0
    for opi in range(Int(input[0])):
        if cursor>=Int(length):return -1
        let op=input[cursor];cursor+=1
        if op==0:
            if cursor>=Int(length) or size>=64:return -1
            if size==data_capacity:
                if active==0:
                    for i in range(size):b[i]=a[i]
                    active=1
                else:
                    for i in range(size):a[i]=b[i]
                    active=0
                data_capacity=10 if data_capacity==0 else data_capacity*2
            if active==0:a[size]=input[cursor]
            else:b[size]=input[cursor]
            size+=1;cursor+=1
        elif op==1:
            if cursor+1>=Int(length):return -1
            let idx=input[cursor];let value=input[cursor+1];cursor+=2
            if idx<0 or idx>=Int64(size):return -1
            if active==0:a[Int(idx)]=value
            else:b[Int(idx)]=value
        elif op==2 or op==3:
            if cursor>=Int(length):return -1
            let idx=input[cursor];cursor+=1
            if idx<0 or idx>=Int64(size):return -1
            if op==2:
                if len(queries)>=128:return -1
                queries.append(a[Int(idx)] if active==0 else b[Int(idx)])
            else:
                for i in range(Int(idx),size-1):
                    if active==0:a[i]=a[i+1]
                    else:b[i]=b[i+1]
                size-=1
        elif op>=4 and op<=6:
            if len(queries)>=128:return -1
            if op==4:queries.append(Int64(size))
            elif op==5:queries.append(Int64(data_capacity))
            else:queries.append(1 if size==0 else 0)
        else:return -1
    if cursor!=Int(length):return -1
    let words=3+len(queries)+size
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or capacity_out<c_size_t(words*8):return -2
    dynamicarray_put(out,0,Int64(len(queries)))
    for i in range(len(queries)):dynamicarray_put(out,i+1,queries[i])
    dynamicarray_put(out,len(queries)+1,Int64(size));dynamicarray_put(out,len(queries)+2,Int64(data_capacity))
    for i in range(size):dynamicarray_put(out,len(queries)+3+i,a[i] if active==0 else b[i])
    return Int64(words)
