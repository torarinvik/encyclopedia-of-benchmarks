fn p55_reverse_add(inout digits:InlineArray[UInt8,64],length:Int)->Int:
    var reverse_length=length
    while reverse_length>0 and digits[length-reverse_length]==0:reverse_length-=1
    let width=length if length>reverse_length else reverse_length;var next=InlineArray[UInt8,64](fill=0);var carry=0
    for pos in range(width):
        let left=Int(digits[pos]) if pos<length else 0
        let right=Int(digits[length-1-pos]) if pos<reverse_length else 0
        let sum=left+right+carry;next[pos]=UInt8(sum%10);carry=sum//10
    var newlen=width
    if carry>0:next[newlen]=UInt8(carry);newlen+=1
    for i in range(newlen):digits[i]=next[i]
    return newlen
fn p55_palindrome(digits:InlineArray[UInt8,64],length:Int)->Bool:
    for left in range(length//2):if digits[left]!=digits[length-1-left]:return False
    return True
@export("problem55")
fn problem55(limit:Int64) abi("C")->Int64:
    if limit<0 or limit>10000:return -1
    var count=Int64(0)
    for start in range(1,Int(limit)):
        var digits=InlineArray[UInt8,64](fill=0);var len=0;var value=start
        while value>0:digits[len]=UInt8(value%10);len+=1;value//=10
        var pal=False
        for _ in range(50):
            len=p55_reverse_add(digits,len)
            if p55_palindrome(digits,len):pal=True;break
        if !pal:count+=1
    return count
