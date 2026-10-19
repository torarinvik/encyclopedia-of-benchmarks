from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer
@export("tim_sort")
fn tim_sort(v:UnsafePointer[Int64,MutAnyOrigin],scratch:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    let count=Int(n)
    if count<2 or v==UnsafePointer[Int64,MutAnyOrigin]() or scratch==UnsafePointer[Int64,MutAnyOrigin]():return
    for base in range(0,count,32):
        let end=min(base+32,count)
        for i in range(base+1,end):
            let x=v[i];var j=i
            while j>base and x<v[j-1]:v[j]=v[j-1];j-=1
            v[j]=x
    var width=32
    while width<count:
        var base=0
        while base<count:
            let mid=min(base+width,count);let end=min(base+2*width,count)
            var left=base;var right=mid;var out=base
            while left<mid and right<end:
                if v[left]<=v[right]:scratch[out]=v[left];left+=1
                else:scratch[out]=v[right];right+=1
                out+=1
            while left<mid:scratch[out]=v[left];left+=1;out+=1
            while right<end:scratch[out]=v[right];right+=1;out+=1
            for j in range(base,end):v[j]=scratch[j]
            base+=2*width
        width*=2
