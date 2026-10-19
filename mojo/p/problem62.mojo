fn p62_signature(cube_in:Int64)->Int64:
    var cube=cube_in;var counts=InlineArray[Int32,10](fill=0);var length=0
    if cube==0:counts[0]=1;length=1
    else:
        while cube>0:counts[cube%10]+=1;length+=1;cube//=10
    var sorted=Int64(0)
    for d in range(10):
        for _ in range(Int(counts[d])):sorted=sorted*16+Int64(d)
    return Int64(length)*4503599627370496+sorted
fn p62_slot(key:Int64)->Int:
    let size=Int64(16384)
    return Int((key%size+(key//size%size)*31+(key//(size*size)%size)*17+(key//(size*size*size)%size)*7)%size)
@export("problem62")
fn problem62(target_count:Int64) abi("C")->Int64:
    if target_count<1 or target_count>5:return -1
    var keys=InlineArray[Int64,16384](fill=0);var first=InlineArray[Int64,16384](fill=0);var counts=InlineArray[Int32,16384](fill=0)
    for base in range(0,8385):
        let cube=Int64(base)*Int64(base)*Int64(base);let key=p62_signature(cube);var slot=p62_slot(key)
        while keys[slot]!=0 and keys[slot]!=key:slot=(slot+1)%16384
        if keys[slot]==0:keys[slot]=key;first[slot]=cube
        counts[slot]+=1
        if Int64(counts[slot])==target_count:return first[slot]
    return -1
