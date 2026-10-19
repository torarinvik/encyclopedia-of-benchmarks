from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
@export("ones_and_zeros")
fn ones_and_zeros(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<3 or n>67 or v[0]<0 or v[0]>32 or v[1]<0 or v[1]>32 or v[2]<0 or v[2]>32 or n!=c_size_t(3+2*v[0]):return -1
    let count=Int(v[0]);let zeros=Int(v[1]);let ones=Int(v[2]);var dp=InlineArray[Int64,1089](fill=0)
    for i in range(count):
        let z=v[3+2*i];let o=v[4+2*i]
        if z<0 or z>32 or o<0 or o>32:return -1
        var a=zeros
        while a>=z:
            var b=ones
            while b>=o:
                let index=a*33+b;let candidate=dp[Int(a-z)*33+Int(b-o)]+1
                if candidate>dp[index]:dp[index]=candidate
                b-=1
            a-=1
    return dp[zeros*33+ones]
