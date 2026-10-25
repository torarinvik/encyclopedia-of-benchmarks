"""Independent bounded oracle for quantized depthwise convolution."""
from collections.abc import Sequence
MAX_CHANNELS=8
MAX_INPUT_LENGTH=1+11*MAX_CHANNELS
MAX_OUTPUT_BYTES=MAX_CHANNELS
INVALID_RESULT=-1
OUTPUT_ERROR=-2

def expected_output(values):
    if not isinstance(values,Sequence) or len(values)<1 or len(values)>MAX_INPUT_LENGTH:return None
    if any(not isinstance(v,int) for v in values):return None
    channels=values[0]
    if not 1<=channels<=MAX_CHANNELS or len(values)!=1+11*channels:return None
    n=channels
    inputs=values[1:1+4*n]
    weights=values[1+4*n:1+8*n]
    biases=values[1+8*n:1+9*n]
    multipliers=values[1+9*n:1+10*n]
    shifts=values[1+10*n:]
    if any(x < -128 or x > 127 for x in inputs+weights):return None
    if any(x < -1_000_000 or x > 1_000_000 for x in biases):return None
    if any(x < 0 or x > 2_147_483_647 for x in multipliers):return None
    if any(x < -8 or x > 0 for x in shifts):return None
    output=[]
    for ch in range(n):
        acc=biases[ch]
        for row in range(4):
            acc+=weights[row*n+ch]*(inputs[row*n+ch]+128)
        total_shift=31-shifts[ch]
        rounded=acc*multipliers[ch]+(1<<(total_shift-1))
        q=rounded//(1<<total_shift)
        q=max(-128,min(127,q))
        output.append(q&255)
    return bytes(output)

def expected_result(values,output_capacity=MAX_OUTPUT_BYTES,output_is_null=False):
    output=expected_output(values)
    if output is None:return INVALID_RESULT
    if output_is_null or output_capacity<len(output):return OUTPUT_ERROR
    return len(output)
