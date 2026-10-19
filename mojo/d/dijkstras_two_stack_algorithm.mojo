from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
from std.collections import List
comptime EXPR_INVALID:Int64= -1000000001
fn expr_apply(op:Int64,left:Int64,right:Int64)->Int64:
    var value:Int64=0
    if op==43:value=left+right
    elif op==45:value=left-right
    elif op==42:value=left*right
    elif op==47:
        if right==0 or left%right!=0:return EXPR_INVALID
        value=left/right
    else:return EXPR_INVALID
    return EXPR_INVALID if value< -1000000000 or value>1000000000 else value
@export("dijkstras_two_stack_algorithm")
fn dijkstras_two_stack_algorithm(input:UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t) abi("C")->Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length==0 or length>511:return EXPR_INVALID
    var operands=List[Int64](capacity=256);var operators=List[Int64](capacity=256);var parens=0
    for i in range(Int(length)):
        let t=input[i]
        if t>=48 and t<=57:operands.append(t-48)
        elif t==40:parens+=1
        elif t==43 or t==45 or t==42 or t==47:operators.append(t)
        elif t==41:
            if parens==0 or len(operators)==0 or len(operands)<2:return EXPR_INVALID
            parens-=1;let op=operators[len(operators)-1];operators.pop();let right=operands[len(operands)-1];operands.pop();let left=operands[len(operands)-1];operands.pop();let result=expr_apply(op,left,right)
            if result==EXPR_INVALID:return EXPR_INVALID
            operands.append(result)
        else:return EXPR_INVALID
        if len(operands)>256 or len(operators)>256 or parens>128:return EXPR_INVALID
    return operands[0] if parens==0 and len(operators)==0 and len(operands)==1 else EXPR_INVALID
