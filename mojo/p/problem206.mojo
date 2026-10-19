fn p206_form(value_in:Int64)->Bool:
    var value=value_in;var digit=Int64(9)
    while value>0:
        if value%10!=digit:return False
        value//=100;digit-=1
    return True
@export("problem206")
fn problem206(unused:Int64) abi("C")->Int64:
    if unused!=0:return -1
    var candidate=Int64(138902663)
    while candidate>=101010103:
        if p206_form(candidate*candidate):return candidate*10
        candidate-=6 if candidate%10==3 else 4
    return -1
