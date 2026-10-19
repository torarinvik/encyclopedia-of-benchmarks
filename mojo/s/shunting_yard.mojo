from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.math import pow
fn sh_prec(c:Int64)->Int:
    if c==94:return 3
    if c==42 or c==47:return 2
    return 1
fn sh_apply(nums:UnsafePointer[Float64,MutAnyOrigin],nc:UnsafePointer[Int32,MutAnyOrigin],ops:UnsafePointer[Int64,MutAnyOrigin],oc:UnsafePointer[Int32,MutAnyOrigin])->Bool:
    if nc[0]<2 or oc[0]<1:return False
    oc[0]-=1;let op=ops[oc[0]];nc[0]-=1;let b=nums[nc[0]];nc[0]-=1;let a=nums[nc[0]];var x=0.0
    if op==43:x=a+b
    elif op==45:x=a-b
    elif op==42:x=a*b
    elif op==47:if b==0:return False;else:x=a/b
    elif op==94:x=pow(a,b)
    else:return False
    if x!=x or x>1e12 or x< -1e12:return False
    nums[nc[0]]=x;nc[0]+=1;return True
@export("shunting_yard")
fn shunting_yard(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Float64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>257:return -1.0e300
    let bytes=a[0];if bytes<1 or bytes>255 or n!=c_size_t(bytes+1):return -1.0e300
    for i in range(Int(bytes)):if a[i+1]<0 or a[i+1]>127:return -1.0e300
    var nums=InlineArray[Float64,16]();var ops=InlineArray[Int64,15]();var nc=InlineArray[Int32,1]();var oc=InlineArray[Int32,1]()
    var pos=1;var operands=0;var opcount=0;var expect=True
    while pos<=Int(bytes):
        while pos<=Int(bytes) and (a[pos]==32 or (a[pos]>=9 and a[pos]<=13)):pos+=1
        if pos>Int(bytes):break
        if expect:
            let start=pos;var digits=0;var value=0.0
            while pos<=Int(bytes) and a[pos]>=48 and a[pos]<=57:value=value*10.0+Float64(a[pos]-48);digits+=1;pos+=1
            if digits==0:return -1.0e300
            if pos<=Int(bytes) and a[pos]==46:
                pos+=1;var fd=0;var scale=0.1
                while pos<=Int(bytes) and a[pos]>=48 and a[pos]<=57:value+=Float64(a[pos]-48)*scale;scale/=10.0;fd+=1;pos+=1
                if fd==0:return -1.0e300
            if pos-start>16 or value>1000000 or operands>=16:return -1.0e300
            nums[nc[0]]=value;nc[0]+=1;operands+=1;expect=False
        else:
            let current=a[pos];if not (current==43 or current==45 or current==42 or current==47 or current==94) or opcount>=15:return -1.0e300
            while oc[0]>0:
                let prev=ops[oc[0]-1];if sh_prec(prev)<sh_prec(current) or (sh_prec(prev)==sh_prec(current) and current==94):break
                if not sh_apply(nums.unsafe_ptr(),nc.unsafe_ptr(),ops.unsafe_ptr(),oc.unsafe_ptr()):return -1.0e300
            ops[oc[0]]=current;oc[0]+=1;opcount+=1;pos+=1;expect=True
    if expect or operands==0 or opcount+1!=operands:return -1.0e300
    while oc[0]>0:if not sh_apply(nums.unsafe_ptr(),nc.unsafe_ptr(),ops.unsafe_ptr(),oc.unsafe_ptr()):return -1.0e300
    if nc[0]!=1:return -1.0e300
    return nums[0]
