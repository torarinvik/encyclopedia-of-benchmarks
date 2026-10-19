from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("damm")
fn damm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 258: return -1
    let mode=input[0];let n=input[1]
    if (mode!=0 and mode!=1) or n<1 or n>256 or length!=c_size_t(n+2):return -1
    var table=List[Int64](length=100,fill=0)
    let rows=List[Int64](capacity=100)
    rows.append(0);rows.append(3);rows.append(1);rows.append(7);rows.append(5);rows.append(9);rows.append(8);rows.append(6);rows.append(4);rows.append(2)
    rows.append(7);rows.append(0);rows.append(9);rows.append(2);rows.append(1);rows.append(5);rows.append(4);rows.append(8);rows.append(6);rows.append(3)
    rows.append(4);rows.append(2);rows.append(0);rows.append(6);rows.append(8);rows.append(7);rows.append(1);rows.append(3);rows.append(5);rows.append(9)
    rows.append(1);rows.append(7);rows.append(5);rows.append(0);rows.append(9);rows.append(8);rows.append(3);rows.append(4);rows.append(2);rows.append(6)
    rows.append(6);rows.append(1);rows.append(2);rows.append(3);rows.append(0);rows.append(4);rows.append(5);rows.append(9);rows.append(7);rows.append(8)
    rows.append(3);rows.append(6);rows.append(7);rows.append(4);rows.append(2);rows.append(0);rows.append(9);rows.append(5);rows.append(8);rows.append(1)
    rows.append(5);rows.append(8);rows.append(6);rows.append(9);rows.append(7);rows.append(2);rows.append(0);rows.append(1);rows.append(3);rows.append(4)
    rows.append(8);rows.append(9);rows.append(4);rows.append(5);rows.append(3);rows.append(6);rows.append(2);rows.append(0);rows.append(1);rows.append(7)
    rows.append(9);rows.append(4);rows.append(3);rows.append(8);rows.append(6);rows.append(1);rows.append(7);rows.append(2);rows.append(0);rows.append(5)
    rows.append(2);rows.append(5);rows.append(8);rows.append(1);rows.append(4);rows.append(3);rows.append(6);rows.append(7);rows.append(9);rows.append(0)
    for i in range(100): table[i]=rows[i]
    var state=0
    for i in range(Int(n)):
        let d=input[i+2]
        if d<0 or d>9:return -1
        state=Int(table[state*10+Int(d)])
    if mode==1:return Int64(state)
    if state==0:return 1
    return 0
