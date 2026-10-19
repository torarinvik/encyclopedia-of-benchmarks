fn p145_count(remaining:Int,carry:Int,inout digits:InlineArray[Int32,9],length:Int)->Int64:
    if remaining==0:
        if digits[0]==0 or digits[length-1]==0:return 0
        var c=carry
        for i in range(length//2):
            let j=length-1-i;c+=Int(digits[i]+digits[j])
            if c%2==0:return 0
            c//=10
        return 1
    if remaining==1:
        if carry%2==0:return 0
        var result=Int64(0)
        for digit in range(10):
            digits[length//2]=Int32(digit)
            result+=p145_count(0,(carry+2*digit)//10,digits,length)
        return result
    var result=Int64(0);let right=(length+remaining)//2-1;let left=(length-remaining)//2
    for d1 in range(10):
        digits[right]=Int32(d1);let parity=1 if (carry+d1)%2==0 else 0
        for d2 in range(parity,10,2):
            digits[left]=Int32(d2)
            result+=p145_count(remaining-2,(carry+d1+d2)//10,digits,length)
    return result
@export("problem145")
fn problem145(max_power:Int64) abi("C")->Int64:
    if max_power>9:return -1
    if max_power<=0:return 0
    var digits=InlineArray[Int32,9](fill=0);var total=Int64(0)
    for length in range(1,Int(max_power+1)):
        if (length-1)%4==0:continue
        total+=p145_count(length,0,digits,length)
    return total
