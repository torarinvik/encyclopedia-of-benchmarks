from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn pmt_append(inout b:InlineArray[UInt8,1024],inout pos:Int,x:Int64):
    var v=x
    if v<0:b[pos]=45;pos+=1;v=-v
    var digs=InlineArray[UInt8,24](fill=0);var k=0
    if v==0:digs[k]=48;k+=1
    while v>0:digs[k]=UInt8(48+v%10);k+=1;v//=10
    for i in range(k):b[pos]=digs[k-1-i];pos+=1
@export("print_multiplication_table")
fn print_multiplication_table(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]< -1000000 or v[0]>1000000 or v[1]< -20 or v[1]>20:return -1
    var buf=InlineArray[UInt8,1024](fill=0);var pos=0
    for i in range(1,Int(v[1])+1):
        if i>1:buf[pos]=10;pos+=1
        pmt_append(buf,pos,v[0]);buf[pos]=32;pos+=1;buf[pos]=42;pos+=1;buf[pos]=32;pos+=1
        pmt_append(buf,pos,Int64(i));buf[pos]=32;pos+=1;buf[pos]=61;pos+=1;buf[pos]=32;pos+=1
        pmt_append(buf,pos,v[0]*Int64(i))
    if (pos>0 and out==UnsafePointer[UInt8,MutAnyOrigin]()) or cap<c_size_t(pos):return -2
    for i in range(pos):out[i]=buf[i]
    return Int64(pos)
