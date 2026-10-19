from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn hampel_sorted_insert(values:List[Float64],value:Float64):
    var pos=len(values);values.append(value)
    while pos>0 and values[pos-1]>value:values[pos]=values[pos-1];pos-=1
    values[pos]=value
fn hampel_median(values:List[Float64])->Float64:
    let n=len(values)
    if n%2==1:return values[n//2]
    return 0.5*(values[n//2-1]+values[n//2])
fn hampel_store(output:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,value:Int64):
    let bits=bitcast[UInt64](value)
    for b in range(8):output[offset+b]=UInt8((bits>>UInt(8*b))&255)
@export("hampel_filter")
fn hampel_filter(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1:return -1
    let n=input[0]
    if n<0 or n>128 or length!=c_size_t(n+1):return -1
    for i in range(Int(n)):if input[i+1]< -1000 or input[i+1]>1000:return -1
    let bytes=Int(n)*8
    if capacity<c_size_t(bytes) or (n>0 and output==UnsafePointer[UInt8,MutAnyOrigin]()):return -2
    var staged=List[Int64](capacity=Int(n));var raw_window=List[Float64](capacity=3)
    for i in range(Int(n)):
        if len(raw_window)==3:
            for j in range(2):raw_window[j]=raw_window[j+1]
            _=raw_window.pop()
        raw_window.append(Float64(input[i+1]))
        var sorted=List[Float64](capacity=3)
        for j in range(len(raw_window)):hampel_sorted_insert(sorted,raw_window[j])
        let med=hampel_median(sorted);var deviations=List[Float64](capacity=3)
        for j in range(len(raw_window)):deviations.append(abs(raw_window[j]-med))
        var sorted_dev=List[Float64](capacity=3)
        for j in range(len(deviations)):hampel_sorted_insert(sorted_dev,deviations[j])
        let mad=hampel_median(sorted_dev);let value=Float64(input[i+1]);let dist=abs(value-med)
        staged.append(Int64(med if dist>3.0*1.4826*mad else value))
    for i in range(Int(n)):hampel_store(output,i*8,staged[i])
    return Int64(bytes)
