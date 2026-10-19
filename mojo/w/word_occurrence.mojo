from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn wo_space(c:Int64)->Bool:return (c>=9 and c<=13) or (c>=28 and c<=32)
fn wo_u32(o:UnsafePointer[UInt8,MutAnyOrigin],at:Int,v:Int):
    for b in range(4):o[at+b]=UInt8((v>>(8*b))&255)
@export("word_occurrence")
fn word_occurrence(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>1025:return -1
    let size=a[0]
    if size<0 or size>1024 or n!=c_size_t(size+1):return -1
    for i in range(Int(size)):if a[i+1]<0 or a[i+1]>127:return -1
    var starts=InlineArray[Int32,1024]();var lens=InlineArray[Int32,1024]();var freq=InlineArray[Int32,1024]();var count=0;var i=0
    while i<Int(size):
        while i<Int(size) and wo_space(a[i+1]):i+=1
        if i>=Int(size):break
        let start=i
        while i<Int(size) and not wo_space(a[i+1]):i+=1
        let length=i-start;var found= -1
        for k in range(count):
            if lens[k]==length:
                var same=true
                for j in range(length):if a[Int(starts[k])+j+1]!=a[start+j+1]:same=false
                if same:found=k
        if found>=0:freq[found]+=1
        else:starts[count]=Int32(start);lens[count]=Int32(length);freq[count]=1;count+=1
    var required=4
    for k in range(count):required+=8+Int(lens[k])
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(required):return -2
    wo_u32(o,0,count);var p=4
    for k in range(count):
        wo_u32(o,p,Int(lens[k]));p+=4
        for j in range(Int(lens[k])):o[p]=UInt8(a[Int(starts[k])+j+1]);p+=1
        wo_u32(o,p,Int(freq[k]));p+=4
    return Int64(p)
