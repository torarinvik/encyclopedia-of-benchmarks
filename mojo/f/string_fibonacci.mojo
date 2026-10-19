from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn sf_add(left:InlineArray[UInt8,80],leftn:Int,right:InlineArray[UInt8,80],rightn:Int,
          mut result:InlineArray[UInt8,80])->Int:
    var i=leftn-1;var j=rightn-1;var carry=0;var count=0
    var reversed=InlineArray[UInt8,80](fill=0)
    while i>=0 or j>=0 or carry!=0:
        let a=Int(left[i])-48 if i>=0 else 0
        let b=Int(right[j])-48 if j>=0 else 0
        let s=a+b+carry
        reversed[count]=UInt8(48+s%10);count+=1;carry=s//10;i-=1;j-=1
    for k in range(count):result[k]=reversed[count-1-k]
    return count

@export("string_fibonacci")
fn string_fibonacci(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
                    output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=1 or input[0]<0 or input[0]>256:return -1
    var minus_one=InlineArray[UInt8,80](fill=0);var minus_two=InlineArray[UInt8,80](fill=0)
    minus_one[0]=49;minus_two[0]=48
    var one_len=1;var two_len=1
    for _ in range(Int(input[0])):
        var sum=InlineArray[UInt8,80](fill=0)
        let sum_len=sf_add(minus_one,one_len,minus_two,two_len,mut sum)
        minus_two=minus_one;two_len=one_len;minus_one=sum;one_len=sum_len
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(two_len):return -2
    for i in range(two_len):output[i]=minus_two[i]
    return Int64(two_len)
