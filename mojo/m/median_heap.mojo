from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray

fn medheap_store(out:UnsafePointer[UInt8,MutAnyOrigin],pos:Int,x:Int64):
    let bits=bitcast[UInt64](x)
    for b in range(8):out[pos+b]=UInt8((bits>>UInt64(8*b))&255)

@export("median_heap")
fn median_heap(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>514 or v[0]<0 or v[0]>256 or n!=c_size_t(1+2*v[0]):return -1
    let operations=Int(v[0]);var live=InlineArray[Int64,64](fill=0);var size=0;var results=InlineArray[Int64,256](fill=0)
    for i in range(operations):
        let op=v[1+2*i];let arg=v[2+2*i]
        if op==0:
            if arg< -2147483648 or arg>2147483647 or size>=64:return -1
            var j=size;while j>0 and live[j-1]>arg:live[j]=live[j-1];j-=1;live[j]=arg;size+=1
            results[i]= -9223372036854775808
        elif op>=1 and op<=4:
            if arg!=0:return -1
            if op==1:results[i]= -9223372036854775808 if size==0 else live[(size-1)/2]
            elif op==2:
                if size==0:results[i]= -9223372036854775808
                else:
                    let index=(size-1)/2;results[i]=live[index]
                    for j in range(index,size-1):live[j]=live[j+1]
                    size-=1
            elif op==3:results[i]=Int64(size)
            else:results[i]=1 if size==0 else 0
        else:return -1
    let bytes=operations*8
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(operations):medheap_store(out,i*8,results[i])
    return Int64(bytes)
