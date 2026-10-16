"""Bounded source-order evaluator for single-digit prefix expressions."""
MAX_TOKENS = 31
MAX_INPUT_LENGTH = 63
INVALID_RESULT = -1e300
OPERATORS = {43, 45, 42, 47}

def expected_result(values: list[int]) -> float:
    if (not isinstance(values,list) or not 2<=len(values)<=MAX_INPUT_LENGTH
            or any(type(x) is not int or not 0<=x<=127 for x in values)):
        return INVALID_RESULT
    length=values[0]
    if not 1<=length<=MAX_INPUT_LENGTH-1 or len(values)!=length+1:return INVALID_RESULT
    data=values[1:]
    if any(x not in OPERATORS and not 48<=x<=57 and x!=32 for x in data):return INVALID_RESULT
    try:text=bytes(data).decode('ascii')
    except UnicodeDecodeError:return INVALID_RESULT
    if not text or text.startswith(' ') or text.endswith(' ') or '  ' in text:return INVALID_RESULT
    tokens=text.split(' ')
    if len(tokens)>MAX_TOKENS or any(len(t)!=1 for t in tokens):return INVALID_RESULT
    stack=[]
    try:
        for token in reversed(tokens):
            code=ord(token)
            if 48<=code<=57:stack.append(float(code-48))
            elif code in OPERATORS:
                if len(stack)<2:return INVALID_RESULT
                first=stack.pop(); second=stack.pop()
                if code==43:stack.append(first+second)
                elif code==45:stack.append(first-second)
                elif code==42:stack.append(first*second)
                else:
                    if second==0:return INVALID_RESULT
                    stack.append(first/second)
            else:return INVALID_RESULT
    except (OverflowError,ZeroDivisionError):return INVALID_RESULT
    if len(stack)!=1:return INVALID_RESULT
    result=stack[0]
    return result if abs(result)<1e299 else INVALID_RESULT
