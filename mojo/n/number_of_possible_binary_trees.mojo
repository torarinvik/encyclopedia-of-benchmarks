@export("number_of_possible_binary_trees")
fn number_of_possible_binary_trees(n:Int64) abi("C")->Int64:
    if n<1 or n>14:return -1
    var choose:Int64=1
    for i in range(1,Int(n)+1):choose=choose*(Int64(n)+Int64(i))/Int64(i)
    choose=choose/(n+1)
    var fact:Int64=1
    for i in range(2,Int(n)+1):fact*=i
    return choose*fact
