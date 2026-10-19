from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn msnes_read(b:UnsafePointer[UInt8,MutAnyOrigin],i:Int)->Int32:
    let u=UInt32(b[i*4])|(UInt32(b[i*4+1])<<8)|(UInt32(b[i*4+2])<<16)|(UInt32(b[i*4+3])<<24)
    return Int32(u)
fn msnes_write(b:UnsafePointer[UInt8,MutAnyOrigin],i:Int,x:Int32):
    let u=UInt32(x)
    for j in range(4):b[i*4+j]=UInt8((u>>(j*8))&255)
fn msnes_merge(b:UnsafePointer[UInt8,MutAnyOrigin],s:Int,m:Int,e:Int,base:Int32):
    var i=s;var j=m+1;var k=s
    while i<=m and j<=e:
        let l=msnes_read(b,i)%base;let r=msnes_read(b,j)%base;let cur=msnes_read(b,k)
        if l<=r:msnes_write(b,k,cur+l*base);i+=1
        else:msnes_write(b,k,cur+r*base);j+=1
        k+=1
    while i<=m:
        let cur=msnes_read(b,k);let x=msnes_read(b,i)%base;msnes_write(b,k,cur+x*base);i+=1;k+=1
    while j<=e:
        let cur=msnes_read(b,k);let x=msnes_read(b,j)%base;msnes_write(b,k,cur+x*base);j+=1;k+=1
    for z in range(s,e+1):msnes_write(b,z,msnes_read(b,z)/base)
fn msnes_sort(b:UnsafePointer[UInt8,MutAnyOrigin],s:Int,e:Int,base:Int32):
    if s>=e:return
    let m=s+(e-s)//2;msnes_sort(b,s,m,base);msnes_sort(b,m+1,e,base);msnes_merge(b,s,m,e,base)

@export("merge_sort_no_extra_space")
fn merge_sort_no_extra_space(v:UnsafePointer[Int32,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int32,ImmutAnyOrigin]() or n>256:return -1
    var mx:Int32=0
    for i in range(Int(n)):
        if v[i]<0 or v[i]>32767:return -1
        if v[i]>mx:mx=v[i]
    let bytes=Int(n)*4
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    for i in range(Int(n)):
        let x=UInt32(v[i]);for j in range(4):out[i*4+j]=UInt8((x>>(j*8))&255)
    if n>1:msnes_sort(out,0,Int(n)-1,mx+1)
    return Int64(bytes)
