@export("problem63")
fn problem63(max_base:Int64,max_power:Int64) abi("C")->Int64:
    let mb=10 if max_base>10 else Int(max_base);let mp=22 if max_power>22 else Int(max_power);var count=Int64(0)
    for base in range(1,mb):
        for power in range(1,mp):
            var digits=InlineArray[Int32,32](fill=0);digits[0]=1;var length=1
            for _ in range(power):
                var carry=0
                for i in range(length):let v=digits[i]*base+carry;digits[i]=v%10;carry=v//10
                while carry>0:digits[length]=carry%10;length+=1;carry//=10
            if length==power:count+=1
    return count
