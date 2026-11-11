@export("leonardo_number")
def leonardo_number(n:Int64) abi("C")->Int64:
    if n<0 or n>89:return -1
    var previous:Int64=1;var current:Int64=1
    for _ in range(2,Int(n)+1):var next=current+previous+1;previous=current;current=next
    return current
