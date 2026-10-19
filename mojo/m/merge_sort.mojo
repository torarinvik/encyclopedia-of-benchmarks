from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("merge_sort")
fn merge_sort(v:UnsafePointer[Int64,MutAnyOrigin],scratch:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    var width=1
    while width<Int(n):
        var low=0
        while low<Int(n):
            let mid=min(low+width,Int(n));let high=min(mid+width,Int(n));var i=low;var j=mid;var k=low
            while i<mid and j<high:
                if v[i]<=v[j]:scratch[k]=v[i];i+=1
                else:scratch[k]=v[j];j+=1
                k+=1
            while i<mid:scratch[k]=v[i];i+=1;k+=1
            while j<high:scratch[k]=v[j];j+=1;k+=1
            for z in range(low,high):v[z]=scratch[z]
            low=high
        if width>Int(n)//2:break
        width*=2
