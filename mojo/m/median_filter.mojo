from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
from std.collections import InlineArray
from std.math import floor,isfinite

@export("median_filter")
fn median_filter(v:UnsafePointer[Float64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[Float64,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Float64,ImmutAnyOrigin]() or n<2 or n>66:return -1
    let wv=v[0];let cv=v[1]
    if not isfinite(wv) or floor(wv)!=wv or wv<1.0 or wv>16.0 or not isfinite(cv) or floor(cv)!=cv or cv<0.0 or cv>64.0:return -1
    let window=Int(wv);let count=Int(cv);if n!=c_size_t(2+count):return -1
    var samples=InlineArray[Float64,64](fill=0.0)
    for i in range(count):
        let x=v[i+2];if not isfinite(x) or x< -1000000.0 or x>1000000.0:return -1
        samples[i]=x
    if out==UnsafePointer[Float64,MutAnyOrigin]() or cap<c_size_t(count):return -2
    var arrival=InlineArray[Float64,16](fill=0.0);var sorted=InlineArray[Float64,16](fill=0.0);var result=InlineArray[Float64,64](fill=0.0)
    var size=0;var oldest=0
    for i in range(count):
        let x=samples[i]
        if size==window:
            var pos=0;while pos<size and sorted[pos]<arrival[oldest]:pos+=1
            for shift in range(pos+1,size):sorted[shift-1]=sorted[shift]
            size-=1
        var pos=0;while pos<size and sorted[pos]<x:pos+=1
        for rev in range(size-pos):let shift=size-rev;sorted[shift]=sorted[shift-1]
        sorted[pos]=x;arrival[oldest]=x;oldest=(oldest+1)%window;size+=1
        let middle=size/2
        result[i]=sorted[middle] if size%2!=0 else 0.5*(sorted[middle-1]+sorted[middle])
    for i in range(count):out[i]=result[i]
    return Int64(count)
