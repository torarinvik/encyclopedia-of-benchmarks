@export("twos_complement_of_binary")
fn twos_complement_of_binary(n:Int64) abi("C")->Int64:
    if n<0 or n>1111111111111111:return -1
    var x=n;var digits=InlineArray[Int,16]();var count=0
    if x==0:return 0
    while x>0:
        let d=Int(x%10)
        if d>1:return -1
        digits[count]=d;count+=1;x/=10
    var found=false
    for i in range(count):
        if found:digits[i]=1-digits[i]
        elif digits[i]==1:found=true
    var result:Int64=0;var place:Int64=1
    for i in range(count):result+=Int64(digits[i])*place;place*=10
    return result
