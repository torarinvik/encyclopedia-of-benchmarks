@export("problem24")
fn problem24(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    var digits=InlineArray[Int32,10](fill=0)
    for i in range(10):digits[i]=Int32(i)
    var rank=999999;var result=Int64(0);var factorial=3628800
    for position in range(10):
        factorial//=10-position
        let choice=rank//factorial;rank%=factorial;let digit=digits[choice]
        result=result*10+Int64(digit)
        for j in range(choice,9-position):digits[j]=digits[j+1]
    return result
