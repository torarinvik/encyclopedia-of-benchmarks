@export("squares_sequence")
fn squares_sequence(index:Int64) abi("C")->Int64:
    if index<0 or index>3037000499:return -1
    return index*index
