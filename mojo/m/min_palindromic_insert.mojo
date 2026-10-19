from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
fn mpi_put(out:UnsafePointer[UInt8,MutAnyOrigin],mut p:Int,x:Int64):
    let u=UInt64(x)
    for b in range(8):out[p]=UInt8((u>>(8*b))&255);p+=1
@export("min_palindromic_insert")
fn min_palindromic_insert(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t,out:UnsafePointer[UInt8,MutAnyOrigin],cap:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257 or v[0]<1 or v[0]>256 or Int(n)!=Int(v[0])+1:return -1
    let count=Int(v[0]);var chars=InlineArray[Int64,256](fill=0);var dp=InlineArray[Int64,65536](fill=0)
    for i in range(count):if v[i+1]<32 or v[i+1]>126:return -1;chars[i]=v[i+1]
    for span in range(2,count+1):
        for left in range(count-span+1):
            let right=left+span-1
            if chars[left]==chars[right]:dp[left*256+right]=if span>2:dp[(left+1)*256+right-1] else:0
            else:
                let a=dp[(left+1)*256+right];let b=dp[left*256+right-1];dp[left*256+right]=(if a<b:a else:b)+1
    let insertions=Int(dp[count-1]);let length=count+insertions;var pal=InlineArray[Int64,511](fill=0)
    var left=0;var right=count-1;var ol=0;var oright=length-1
    while left<=right:
        if chars[left]==chars[right]:pal[ol]=chars[left];pal[oright]=chars[right];left+=1;if right==0:break;right-=1
        elif dp[(left+1)*256+right]<dp[left*256+right-1]:pal[ol]=chars[left];pal[oright]=chars[left];left+=1
        else:pal[ol]=chars[right];pal[oright]=chars[right];if right==0:break;right-=1
        ol+=1
        if oright==0:break
        oright-=1
    let bytes=16+length
    if out==UnsafePointer[UInt8,MutAnyOrigin]() or cap<c_size_t(bytes):return -2
    var p=0;mpi_put(out,mut p,Int64(insertions));mpi_put(out,mut p,Int64(length))
    for i in range(length):out[p+i]=UInt8(pal[i])
    return Int64(bytes)
