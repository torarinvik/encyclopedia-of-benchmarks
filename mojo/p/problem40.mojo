@export("problem40")
fn problem40(ignored:Int64) abi("C")->Int64:
    if ignored!=0:return -1
    let positions=InlineArray[Int64,7](fill=0);var pos=InlineArray[Int64,7](fill=0)
    pos[0]=1;pos[1]=10;pos[2]=100;pos[3]=1000;pos[4]=10000;pos[5]=100000;pos[6]=1000000
    var product=Int64(1)
    for k in range(7):
        var index=pos[k];var width=Int64(1);var block=Int64(9)
        while index>width*block:index-=width*block;width+=1;block*=10
        let number=block//9+((index-1)//width)
        let offset=Int((index-1)%width);var divisor=Int64(1)
        for _ in range(Int(width-offset-1)):divisor*=10
        product*=((number//divisor)%10)
    return product
