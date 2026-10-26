"""Event-driven independent verifier for parallel-machine SRPT."""
import struct
from collections.abc import Sequence

MAX_INPUT_LENGTH=26
MAX_OUTPUT_BYTES=104

def expected_output(values:Sequence[int]|None,capacity:int|None=None,output_is_null:bool=False,input_is_null:bool=False,input_length:int|None=None)->tuple[int,bytes]:
    if type(output_is_null) is not bool or type(input_is_null) is not bool:return -1,b""
    if capacity is not None and (type(capacity) is not int or capacity<0):return -1,b""
    if input_length is not None and (type(input_length) is not int or not 0<=input_length<=MAX_INPUT_LENGTH):return -1,b""
    if input_is_null and values not in (None,[],()):return -1,b""
    if not input_is_null and values is not None and input_length is not None and input_length!=len(values):return -1,b""
    if input_is_null or values is None or not isinstance(values,(list,tuple)):return -1,b""
    if len(values)<4 or len(values)>MAX_INPUT_LENGTH or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):return -1,b""
    machines,n=values[:2]
    if not 1<=machines<=4 or not 1<=n<=12 or len(values)!=2+2*n:return -1,b""
    releases=[];remaining=[]
    for i in range(n):
        release,work=values[2+2*i:4+2*i]
        if not 0<=release<=50 or not 1<=work<=10:return -1,b""
        releases.append(release);remaining.append(work)
    completion=[-1]*n;time=0;finished=0
    while finished<n:
        ready=sorted((remaining[i],i) for i in range(n) if remaining[i]>0 and releases[i]<=time)
        running=[i for _,i in ready[:machines]]
        if not running:
            time=min(releases[i] for i in range(n) if remaining[i]>0)
            continue
        next_release=min((releases[i] for i in range(n) if remaining[i]>0 and releases[i]>time),default=None)
        step=min(remaining[i] for i in running)
        if next_release is not None:step=min(step,next_release-time)
        time+=step
        for i in running:
            remaining[i]-=step
            if remaining[i]==0:completion[i]=time;finished+=1
    total=sum(completion[i]-releases[i] for i in range(n))
    payload=b"".join(struct.pack("<q",x) for x in [total,*completion])
    if output_is_null or capacity is not None and capacity<len(payload):return -2,b""
    return len(payload),payload
