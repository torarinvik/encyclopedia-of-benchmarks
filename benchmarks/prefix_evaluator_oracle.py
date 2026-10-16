"""Oracle for prefix evaluation with bounded Java int semantics."""
MAX_INPUT_LENGTH = 129
OPS = {-9000000000000000001: "+", -9000000000000000002: "-", -9000000000000000003: "*", -9000000000000000004: "/"}
def _i32(x):
    x &= 0xffffffff
    return x if x < 0x80000000 else x - 0x100000000
def expected_result(values):
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH: return -1
    if any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values): return -1
    n=values[0]
    if not 1 <= n <= 128 or len(values) != n+1: return -1
    stack=[]
    for token in reversed(values[1:]):
        if token in OPS:
            if len(stack)<2:return -1
            a=stack.pop();b=stack.pop();op=OPS[token]
            if op=="+":z=_i32(a+b)
            elif op=="-":z=_i32(a-b)
            elif op=="*":z=_i32(a*b)
            else:
                if b==0:return -1
                q=abs(a)//abs(b);z=q if (a<0)==(b<0) else -q;z=_i32(z)
            stack.append(z)
        elif -(2**31)<=token<2**31:stack.append(token)
        else:return -1
    return stack[0] if len(stack)==1 else -1
