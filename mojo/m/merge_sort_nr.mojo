from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("merge_sort_nr")
fn merge_sort_nr(v:UnsafePointer[Int64,MutAnyOrigin],n:c_size_t) abi("C")->None:
    if v==UnsafePointer[Int64,MutAnyOrigin]() or n>1024:return
    var scratch=InlineArray[Int64,1024](fill=0);var width=1
    while width<Int(n):
        for s in range(0,Int(n),width*2):
            let m=min(s+width,Int(n));let e=min(m+width,Int(n));var i=s;var j=m;var k=s
            while i<m and j<e:
                if v[i]<=v[j]:scratch[k]=v[i];i+=1
                else:scratch[k]=v[j];j+=1
                k+=1
            while i<m:scratch[k]=v[i];i+=1;k+=1
            while j<e:scratch[k]=v[j];j+=1;k+=1
        for i in range(Int(n)):v[i]=scratch[i]
        width*=2
