"""Source-ordered bounded oracle for MinMaxStack operation traces."""
import struct
MIN_CAPACITY = 0
MAX_CAPACITY = 64
MIN_OPERATION_COUNT = 0
MAX_OPERATION_COUNT = 64
MIN_PUSH_VALUE = -(1 << 31)
MAX_PUSH_VALUE = (1 << 31) - 1
MAX_INPUT_VALUES = 2 + 2 * MAX_OPERATION_COUNT
MAX_OUTPUT_BYTES = 24 * MAX_OPERATION_COUNT
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values,output_capacity=MAX_OUTPUT_BYTES):
    if not isinstance(values,(list,tuple)) or len(values)<2 or len(values)>MAX_INPUT_VALUES or any(type(x)is not int or not I64_MIN<=x<=I64_MAX for x in values):return -1,b""
    size,count=values[:2]
    if not MIN_CAPACITY<=size<=MAX_CAPACITY or not MIN_OPERATION_COUNT<=count<=MAX_OPERATION_COUNT:return -1,b""
    pos=2;ops=[]
    for _ in range(count):
        if pos>=len(values):return -1,b""
        op=values[pos];pos+=1
        if op==1:
            if pos>=len(values):return -1,b""
            value=values[pos];pos+=1
            if not MIN_PUSH_VALUE<=value<=MAX_PUSH_VALUE:return -1,b""
        elif op not in (2,3,4,5):return -1,b""
        ops.append((op,value if op==1 else 0))
    if pos!=len(values):return -1,b""
    stack=[];records=[]
    for op,value in ops:
        if op==1:
            if len(stack)==size:records.append((1,4,1));break
            lo=value if not stack else min(stack[-1][1],value);hi=value if not stack else max(stack[-1][2],value)
            stack.append((value,lo,hi));records.append((1,1,1))
        elif op==2:records.append((2,0,stack.pop()[0]) if stack else (2,3,0))
        elif op==3:records.append((3,0,stack[-1][1]) if stack else (3,3,0))
        elif op==4:records.append((4,0,stack[-1][2]) if stack else (4,3,0))
        else:records.append((5,1,1 if stack else 0))
    out=b"".join(struct.pack("<qqq",*r) for r in records)
    if output_capacity<len(out):return -2,b""
    return len(out),out
