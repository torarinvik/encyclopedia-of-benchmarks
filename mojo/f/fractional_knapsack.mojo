from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("fractional_knapsack_benchmark")
fn fractional_knapsack_benchmark(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>258:return -1
    let capacity=input[0];let count=input[1]
    if capacity<0 or capacity>1000000 or count<0 or count>128 or Int(length)!=2+2*Int(count):return -1
    var weights=InlineArray[Int64,128](fill=0)
    var values=InlineArray[Int64,128](fill=0)
    for i in range(Int(count)):
        weights[i]=input[2+2*i];values[i]=input[3+2*i]
        if weights[i]<1 or weights[i]>1000000 or values[i]<0 or values[i]>1000000:return -1
    for i in range(1,Int(count)):
        let cw=weights[i];let cv=values[i]
        var p=i
        while p>0 and values[p-1]*cw<cv*weights[p-1]:
            weights[p]=weights[p-1];values[p]=values[p-1];p-=1
        weights[p]=cw;values[p]=cv
    var remaining=capacity;var total:Int64=0
    for i in range(Int(count)):
        if remaining<=0:break
        if remaining>=weights[i]:
            total+=values[i]*1000000;remaining-=weights[i]
        else:
            total+=values[i]*remaining*1000000/weights[i]
            break
    return total
