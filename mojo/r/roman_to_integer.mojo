from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
fn roman_digit(v:UnsafePointer[Int64,ImmutAnyOrigin],n:Int,pos:Int,one:Int,five:Int,ten:Int)->Int:
    if pos>=n:return 0
    if v[pos]==one:
        if pos+1<n and v[pos+1]==ten:return 146
        if pos+1<n and v[pos+1]==five:return 66
        var count=0
        while pos+count<n and v[pos+count]==one and count<3:count+=1
        if pos+count<n and v[pos+count]==one:return -1
        return count*17
    if v[pos]==five:
        var count=0
        while pos+1+count<n and v[pos+1+count]==one and count<3:count+=1
        if pos+1+count<n and v[pos+1+count]==one:return -1
        return (5+count)*16+1+count
    return 0
@export("roman_to_integer")
fn roman_to_integer(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if n<1 or n>15 or v==UnsafePointer[Int64,ImmutAnyOrigin]():return -1
    for i in range(Int(n)):let x=v[i];if x!=73 and x!=86 and x!=88 and x!=76 and x!=67 and x!=68 and x!=77:return -1
    let size=Int(n);var pos=0;var thousands=0
    while pos<size and v[pos]==77 and thousands<3:pos+=1;thousands+=1
    if pos<size and v[pos]==77:return -1
    let h=roman_digit(v,size,pos,67,68,77);if h<0:return -1;pos+=(h&15)
    let t=roman_digit(v,size,pos,88,76,67);if t<0:return -1;pos+=(t&15)
    let o=roman_digit(v,size,pos,73,86,88);if o<0:return -1;pos+=(o&15)
    if pos!=size:return -1
    let result=thousands*1000+(h>>4)*100+(t>>4)*10+(o>>4)
    if result<1 or result>3999:return -1
    return Int64(result)
