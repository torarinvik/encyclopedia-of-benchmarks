from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
fn digit_count_up_to(bound0:Int64,target:Int)->Int64:
    if bound0<0:return 0
    var bound=bound0;var digits=List[Int](capacity=19)
    while bound>0:digits.append(Int(bound%10));bound/=10
    if len(digits)==0:digits.append(0)
    var loose=List[Int64](length=172,fill=0);var tight=List[Int64](length=172,fill=0);tight[0]=1
    for position in range(len(digits)):
        let limit=digits[len(digits)-position-1];var nextloose=List[Int64](length=172,fill=0);var nexttight=List[Int64](length=172,fill=0)
        for sum in range(target+1):
            for d in range(10):
                if sum+d<=target:nextloose[sum+d]+=loose[sum]
            for d in range(limit+1):
                if sum+d<=target:
                    if d==limit:nexttight[sum+d]+=tight[sum]
                    else:nextloose[sum+d]+=tight[sum]
        loose=nextloose;tight=nexttight
    return loose[target]+tight[target]
@export("digit_dp")
fn digit_dp(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length!=3:return -1
    let lower=input[0];let upper=input[1];let targetv=input[2]
    if lower< -1 or lower>1000000000000000000 or upper< -1 or upper>1000000000000000000 or targetv< -2147483648 or targetv>2147483647:return -1
    if lower>upper or targetv<0 or targetv>171:return 0
    return digit_count_up_to(upper,Int(targetv))-digit_count_up_to(lower-1,Int(targetv))
