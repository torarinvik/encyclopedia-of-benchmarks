@export("square_pyramidal_numbers")
fn square_pyramidal_numbers(n:Int64) abi("C")->Int64:
    if n<0 or n>2097151:return -1
    let x=UInt64(n);return Int64((x*(x+1)*(2*x+1))/6)
