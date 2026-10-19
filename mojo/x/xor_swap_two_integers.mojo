@export("xor_swap_two_integers")
fn xor_swap_two_integers(first:Int64,second:Int64) abi("C")->Int64:
    if first < -32768 or first > 32767 or second < -32768 or second > 32767:return -1
    var a=first+65536 if first<0 else first;var b=second+65536 if second<0 else second
    a=a^b;b=b^a;a=a^b
    let x=a-65536 if a>=32768 else a;let y=b-65536 if b>=32768 else b
    return (x+32768)*65536+(y+32768)
