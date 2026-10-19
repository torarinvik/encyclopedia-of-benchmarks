from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
fn twos_hash(k:Int64,cap:Int)->Int:
    let p:Int64=2147483647
    let norm=(k%p+p)%p
    return Int((norm*48271%p)%Int64(cap))
@export("two_sum")
fn two_sum(a:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if a==UnsafePointer[Int64,ImmutAnyOrigin]() or n<1 or n>257:return -2
    let target=a[0];let count=Int(n-1)
    if target< -2147483648 or target>2147483647:return -2
    var keys=InlineArray[Int64,512]();var first=InlineArray[Int32,512]();var used=InlineArray[Bool,512]();var cap=1
    while cap<count*2:cap*=2
    for i in range(count):
        let current=a[i+1]
        if current< -2147483648 or current>2147483647:return -2
        let complement=target-current;var slot=twos_hash(complement,cap)
        while used[slot] and keys[slot]!=complement:slot=(slot+1)%cap
        if used[slot]:return Int64(first[slot])*256+Int64(i)
        slot=twos_hash(current,cap)
        while used[slot] and keys[slot]!=current:slot=(slot+1)%cap
        if not used[slot]:used[slot]=True;keys[slot]=current;first[slot]=Int32(i)
    return -1
