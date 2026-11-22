from std.ffi import c_size_t
from std.memory import Pointer
from std.origin import ImmUntrackedOrigin
@export("string_is_valid_number")
def string_is_valid_number(input: Optional[Pointer[Int64, ImmUntrackedOrigin]], length: c_size_t) abi("C") -> Int64:
    if length == 0:
        return 0
    if length > 256 or input == None:
        return -1
    var values = input.value()
    for index in range(Int(length)):
        if values[unsafe_offset=index] < 0 or values[unsafe_offset=index] > 127:
            return -1
    var state = 0
    for index in range(Int(length)):
        var character = values[unsafe_offset=index]
        if character>=48 and character<=57:
            if state==0 or state==1:state=2
            elif state==3:state=4
            elif state==5 or state==6:state=7
            elif state!=2 and state!=4 and state!=7:return 0
        elif character==43 or character==45:
            if state==0:state=1
            elif state==5:state=6
            else:return 0
        elif character==46:
            if state==0 or state==1:state=3
            elif state==2:state=4
            else:return 0
        elif character==101 or character==69:
            if state==2 or state==4:state=5
            else:return 0
        else:return 0
    return 1 if state==2 or state==4 or state==7 else 0
