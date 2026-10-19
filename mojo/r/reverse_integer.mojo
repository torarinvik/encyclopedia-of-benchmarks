@export("reverse_integer")
fn reverse_integer(value:Int64) abi("C")->Int64:
    if value< -2147483648 or value>2147483647:return -2147483649
    var x=value;var reversed:Int64=0
    while x!=0:
        let digit=x%10;x/=10
        if reversed>214748364 or (reversed==214748364 and digit>7):return 0
        if reversed< -214748364 or (reversed== -214748364 and digit< -8):return 0
        reversed=reversed*10+digit
    return reversed
