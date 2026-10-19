@export("negative_integers_sequence")
fn negative_integers_sequence(n:Int64) abi("C")->Int64:
    if n<0:return 0
    return -n-1
