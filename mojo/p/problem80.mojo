fn p80_muladd(src:InlineArray[UInt64,16],factor:UInt64,add:UInt64,inout dst:InlineArray[UInt64,16]):
    var carry=add
    for i in range(16):
        let value=src[i]*factor+carry;dst[i]=value%1000000000;carry=value//1000000000
fn p80_ge(left:InlineArray[UInt64,16],right:InlineArray[UInt64,16])->Bool:
    for i in range(15,-1,-1):
        if left[i]!=right[i]:return left[i]>right[i]
    return True
fn p80_sub(inout left:InlineArray[UInt64,16],right:InlineArray[UInt64,16]):
    var borrow=UInt64(0)
    for i in range(16):
        let amount=right[i]+borrow
        if left[i]<amount:left[i]=left[i]+1000000000-amount;borrow=1
        else:left[i]-=amount;borrow=0
@export("problem80")
fn problem80(placeholder:Int64) abi("C")->Int64:
    if placeholder!=0:return -1
    var answer=Int64(0)
    for number in range(2,100):
        var root=UInt64(0)
        while (root+1)*(root+1)<=UInt64(number):root+=1
        if root*root==UInt64(number):continue
        var value=InlineArray[UInt64,16](fill=0);var rem=InlineArray[UInt64,16](fill=0);var scaled=InlineArray[UInt64,16](fill=0);var trial=InlineArray[UInt64,16](fill=0);var sum=Int64(0)
        for step in range(100):
            p80_muladd(rem,100,UInt64(number if step==0 else 0),rem)
            var digit=9
            while digit>=0:
                p80_muladd(value,20,UInt64(digit),scaled);p80_muladd(scaled,UInt64(digit),0,trial)
                if p80_ge(rem,trial):break
                digit-=1
            p80_sub(rem,trial);p80_muladd(value,10,UInt64(digit),value);sum+=Int64(digit)
        answer+=sum
    return answer
