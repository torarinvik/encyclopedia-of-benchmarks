@export("problem56")
fn problem56(a:Int64,b:Int64) abi("C")->Int64:
    if a<1 or a>200 or b<1 or b>200:return -1
    var best=Int64(0)
    for base in range(0,Int(a)):
        var digits=InlineArray[Int32,512](fill=0);digits[0]=1;var length=1
        for power in range(Int(b)):
            var sum=Int64(0)
            for i in range(length):sum+=Int64(digits[i])
            if sum>best:best=sum
            if power+1<Int(b):
                var carry=0
                for i in range(length):let v=digits[i]*base+carry;digits[i]=v%10;carry=v//10
                while carry>0:digits[length]=carry%10;length+=1;carry//=10
    return best
