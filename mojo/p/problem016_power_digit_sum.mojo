from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("problem016_power_digit_sum")
fn problem016_power_digit_sum(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n!=2 or v[0]<0 or v[0]>9 or v[1]<0 or v[1]>1000:return -1
    var digits=InlineArray[Int64,1001](fill=0);var count=1;digits[0]=v[0]
    for _ in range(1,Int(v[1])):
        var carry=Int64(0)
        for i in range(count):let p=digits[i]*v[0]+carry;digits[i]=p%10;carry=p//10
        while carry>0:digits[count]=carry%10;count+=1;carry//=10
    var sum=Int64(0)
    for i in range(count):sum+=digits[i]
    return sum
