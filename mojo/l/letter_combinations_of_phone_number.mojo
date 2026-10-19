from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,MutAnyOrigin,UnsafePointer
fn phone_count(d:Int)->Int:return if d==7 or d==9:4 else:3
fn phone_base(d:Int)->Int:return if d==2:97 elif d==3:100 elif d==4:103 elif d==5:106 elif d==6:109 elif d==7:112 elif d==8:116 else:119
fn phone_expand(v:UnsafePointer[Int64,ImmutAnyOrigin],len:Int,index:Int,out:UnsafePointer[UInt8,MutAnyOrigin],offset:Int,total:Int):
    if index==len:return
    let digit=Int(v[index]);let alternatives=phone_count(digit);let block=total/alternatives;let base=phone_base(digit)
    for letter in range(alternatives):
        let branch=offset+letter*block*len
        for row in range(block):out[branch+row*len+index]=UInt8(base+letter)
        phone_expand(v,len,index+1,out,branch,block)
@export("letter_combinations_of_phone_number")
fn letter_combinations_of_phone_number(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if n==0:return 0
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n>6:return -1
    var count=1
    for i in range(Int(n)):
        if v[i]<2 or v[i]>9:return -1
        count*=phone_count(Int(v[i]))
    let need=count*Int(n)
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(need):return -2
    phone_expand(v,Int(n),0,out,0,count);return Int64(count)
