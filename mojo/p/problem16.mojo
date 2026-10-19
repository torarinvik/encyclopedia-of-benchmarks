@export("problem16")
fn problem16(exponent:Int64) abi("C")->Int64:
    if exponent<0 or exponent>1000:return -1
    var digits=InlineArray[Int32,400](fill=0);digits[0]=1;var length=1
    for _ in range(Int(exponent)):
        var carry=0
        for i in range(length):let v=digits[i]*2+carry;digits[i]=v%10;carry=v//10
        while carry>0:digits[length]=carry%10;length+=1;carry//=10
    var sum=Int64(0)
    for i in range(length):sum+=Int64(digits[i])
    return sum
