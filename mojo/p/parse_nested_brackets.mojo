from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn pnb_scan(s:InlineArray[UInt8,128],lo:Int,hi:Int,mut h:UInt64):
    var depth=0;var begin=0
    for i in range(lo,hi):
        if s[i]==60:
            if depth==0:begin=i
            depth+=1
        elif s[i]==62:
            depth-=1
            if depth==0:
                for j in range(begin,i+1):h=(h*257+UInt64(s[j])+1)%1000000007
                pnb_scan(s,begin+1,i,mut h)
@export("parse_nested_brackets")
fn parse_nested_brackets(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>129 or v[0]<0 or v[0]>128 or Int(n)!=Int(v[0])+1:return -1
    let len=Int(v[0]);var s=InlineArray[UInt8,128](fill=0);var depth=0
    for i in range(len):let x=v[i+1];if x<0 or x>127:return -1;s[i]=UInt8(x);if x==60:depth+=1 elif x==62:depth-=1;if depth<0:return -1
    if depth!=0:return -1
    var h:UInt64=0;pnb_scan(s,0,len,mut h);return Int64(h)
