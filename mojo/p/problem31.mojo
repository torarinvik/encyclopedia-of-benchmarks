@export("problem31")
fn problem31(target:Int64) abi("C")->Int64:
    if target<0 or target>500:return -1
    var ways=InlineArray[Int64,501](fill=0);ways[0]=1
    let coins=InlineArray[Int64,8](fill=0);var c=InlineArray[Int64,8](fill=0);c[0]=1;c[1]=2;c[2]=5;c[3]=10;c[4]=20;c[5]=50;c[6]=100;c[7]=200
    for i in range(8):
        for amount in range(Int(c[i]),Int(target+1)):ways[amount]+=ways[amount-Int(c[i])]
    return ways[Int(target)]
