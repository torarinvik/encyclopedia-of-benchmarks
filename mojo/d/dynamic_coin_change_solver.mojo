from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
@export("dynamic_coin_change_solver")
fn dynamic_coin_change_solver(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<3 or length>11:return -1
    let amountv=input[0];let countv=input[1]
    if amountv<1 or amountv>18 or countv<1 or countv>9 or length!=c_size_t(countv+2):return -1
    let amount=Int(amountv);let count=Int(countv);var coins=List[Int](capacity=9);var has_one=false
    for i in range(count):
        let c=input[i+2]
        if c<1 or c>9:return -1
        for j in range(i):if coins[j]==Int(c):return -1
        coins.append(Int(c));if c==1:has_one=true
    if not has_one:return -1
    for i in range(count):
        for j in range(i+1,count):
            if coins[i]<coins[j]:let t=coins[i];coins[i]=coins[j];coins[j]=t
    var changes=List[Int](length=19*9,fill=0);var sizes=List[Int](length=19,fill=0)
    for value in range(1,amount+1):
        for i in range(count):
            if coins[i]<=value:changes[value*9+sizes[value]]=value-coins[i];sizes[value]+=1
    var code:Int64=0;var current=amount
    for step in range(18):
        var next=2147483647;var min_change=2147483647
        for i in range(sizes[current]):
            let change=changes[current*9+i]
            if change==0:next=0;break
            var minimum=2147483647
            for j in range(sizes[change]):if changes[change*9+j]<minimum:minimum=changes[change*9+j]
            if minimum<min_change:min_change=minimum;next=change
        if next==2147483647:return -1
        code=code*10+Int64(current-next)
        if next==0:return code
        current=next
    return -1
