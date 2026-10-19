@export("problem25")
fn problem25(digits_needed:Int64) abi("C")->Int64:
    if digits_needed<2 or digits_needed>1000:return -1
    var a=InlineArray[Int32,1000](fill=0);var b=InlineArray[Int32,1000](fill=0);a[0]=1;b[0]=1;var la=1;var lb=1;var index=2
    while lb<Int(digits_needed):
        var carry=0;var next=InlineArray[Int32,1000](fill=0);let width=la if la>lb else lb
        for i in range(width):
            let value=(a[i] if i<la else 0)+(b[i] if i<lb else 0)+carry
            next[i]=value%10;carry=value//10
        var ln=width
        if carry>0:next[ln]=carry;ln+=1
        for i in range(1000):a[i]=b[i];b[i]=next[i]
        la=lb;lb=ln;index+=1
    return Int64(index)
