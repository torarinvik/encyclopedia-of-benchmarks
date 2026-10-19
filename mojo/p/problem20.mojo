@export("problem20")
fn problem20(n:Int64) abi("C")->Int64:
    if n<0 or n>100:return -1
    var digits=InlineArray[Int32,200](fill=0);digits[0]=1;var length=1
    for factor in range(2,Int(n+1)):
        var carry=Int64(0)
        for i in range(length):
            let value=Int64(digits[i])*Int64(factor)+carry;digits[i]=Int32(value%10);carry=value//10
        while carry>0:digits[length]=Int32(carry%10);length+=1;carry//=10
    var sum=Int64(0)
    for i in range(length):sum+=Int64(digits[i])
    return sum
