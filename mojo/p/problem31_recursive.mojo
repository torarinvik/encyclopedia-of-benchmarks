fn p31_rec(target:Int64,coin_index:Int)->Int64:
    if target<0:return 0
    if coin_index==0:return 1
    let coins=InlineArray[Int64,8](fill=0);var c=InlineArray[Int64,8](fill=0);c[0]=1;c[1]=2;c[2]=5;c[3]=10;c[4]=20;c[5]=50;c[6]=100;c[7]=200
    return p31_rec(target-c[coin_index],coin_index)+p31_rec(target,coin_index-1)
@export("problem31_recursive")
fn problem31_recursive(target:Int64) abi("C")->Int64:
    if target<0 or target>200:return -1
    return p31_rec(target,7)
