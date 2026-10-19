from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ipv6_hex(c:Int64)->Bool:return (c>=48 and c<=57) or (c>=97 and c<=102) or (c>=65 and c<=70)
fn ipv6_valid(input:UnsafePointer[Int64,ImmutAnyOrigin],start:Int,n:Int)->Bool:
    if n==0:return False
    var groups=0;var glen=0;var compression=0;var in_group=False;var i=0
    while i<n:
        let c=input[start+i]
        if c==58:
            if i+1<n and input[start+i+1]==58:
                if (i>0 and input[start+i-1]==58) or (i+2<n and input[start+i+2]==58) or compression!=0:return False
                if in_group:groups+=1;in_group=False;glen=0
                elif i!=0:return False
                compression+=1;i+=2;continue
            if i==0 or i+1==n or not in_group:return False
            groups+=1;in_group=False;glen=0;i+=1;continue
        if not ipv6_hex(c) or glen==4:return False
        glen+=1;in_group=True;i+=1
    if in_group:groups+=1
    return groups==8 if compression==0 else groups<8

@export("is_ipv6_address_valid")
fn is_ipv6_address_valid(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<1 or input[0]<0 or input[0]>256:return -1
    let n=Int(input[0])
    if Int(length)!=n+1:return -1
    for i in range(n):
        if input[i+1]<0 or input[i+1]>127:return -1
    return 1 if ipv6_valid(input,1,n) else 0
