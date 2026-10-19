from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn ppa_is(text:InlineArray[Int64,12],a:Int,b:Int)->Bool:
    var l=a;var r=b-1
    while l<r:if text[l]!=text[r]:return False;l+=1;r-=1
    return True
fn ppa_enum(text:InlineArray[Int64,12],length:Int,mut ends:InlineArray[Int64,12],mut packed:InlineArray[Int64,16000],mut used:Int,mut parts:Int,start:Int,depth:Int):
    if start==length:
        parts+=1;packed[used]=Int64(depth);used+=1
        for i in range(depth):packed[used]=ends[i];used+=1
        return
    for end in range(start+1,length+1):
        if ppa_is(text,start,end):ends[depth]=Int64(end);ppa_enum(text,length,mut ends,mut packed,mut used,mut parts,end,depth+1)
@export("palindrome_partitioning_all_partitions")
fn palindrome_partitioning_all_partitions(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,o:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or v[0]<0 or v[0]>12 or Int(n)!=Int(v[0])+1:return -1
    let length=Int(v[0]);var text=InlineArray[Int64,12](fill=0)
    for i in range(length):if v[i+1]<0 or v[i+1]>127:return -1;text[i]=v[i+1]
    var ends=InlineArray[Int64,12](fill=0);var packed=InlineArray[Int64,16000](fill=0);var used=1;var parts=0
    ppa_enum(text,length,mut ends,mut packed,mut used,mut parts,0,0);packed[0]=Int64(parts);let bytes=used*8
    if o==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(used):let u=UInt64(packed[i]);for b in range(8):o[8*i+b]=UInt8((u>>(8*b))&255)
    return Int64(bytes)
