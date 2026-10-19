from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn stripped(c:Int64)->Bool:
    return c==46 or c==44 or c==33 or c==63 or c==40 or c==41 or c==91 or c==93 or c==123 or c==125
fn put32(out:UnsafePointer[UInt8,MutAnyOrigin],i:Int,x:Int):
    for j in range(4):out[i+j]=UInt8((x>>(8*j))&255)

@export("largest_smallest_words")
fn largest_smallest_words(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>515:return -1
    let textn=v[0]
    if textn<1 or textn>512 or n!=c_size_t(textn+1):return -1
    for i in range(Int(textn)):
        if v[i+1]<32 or v[i+1]>126:return -1
    var starts=InlineArray[Int64,512](fill=0);var lens=InlineArray[Int64,512](fill=0);var count=0;var i=0
    while i<Int(textn):
        while i<Int(textn) and v[i+1]==32:i+=1
        if i>=Int(textn):break
        let start=i
        while i<Int(textn) and v[i+1]!=32:i+=1
        var a=start;var b=i
        while a<b and stripped(v[a+1]):a+=1
        while b>a and stripped(v[b]):b-=1
        if b>a:starts[count]=a;lens[count]=b-a;count+=1
    if count==0:return -1
    var small=0;var large=0
    for wi in range(1,count):
        if lens[wi]<lens[small]:small=wi
        if lens[wi]>lens[large]:large=wi
    let need=8+Int(lens[small]+lens[large])
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    put32(out,0,Int(lens[small]));put32(out,4+Int(lens[small]),Int(lens[large]))
    for j in range(Int(lens[small])):out[4+j]=UInt8(v[Int(starts[small])+j+1])
    for j in range(Int(lens[large])):out[8+Int(lens[small])+j]=UInt8(v[Int(starts[large])+j+1])
    return Int64(need)
