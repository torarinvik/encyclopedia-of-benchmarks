"""Oracle for bounded non-preemptive priority scheduling order."""
import struct
MAX_INPUT_LENGTH = 31
MAX_OUTPUT_BYTES = 40

def expected_output(values):
    if (not isinstance(values,(list,tuple)) or len(values)<4
            or any(type(x) is not int or not -(2**63)<=x<2**63 for x in values)):
        return -1,b""
    n=values[0]
    if not 1<=n<=10 or len(values)!=1+3*n:return -1,b""
    jobs=[]
    for i in range(n):
        arrival,burst,priority=values[1+3*i:4+3*i]
        if not 0<=arrival<=20 or not 1<=burst<=10 or not 0<=priority<=10:return -1,b""
        jobs.append((arrival,burst,priority,i))
    if len({j[2] for j in jobs})!=n:return -1,b""
    done=[False]*n; order=[]; now=0
    for _ in range(n):
        ready=[j for j in jobs if not done[j[3]] and j[0]<=now]
        if not ready:
            now=min(j[0] for j in jobs if not done[j[3]])
            ready=[j for j in jobs if not done[j[3]] and j[0]<=now]
        job=min(ready,key=lambda j:(j[2],j[0]))
        done[job[3]]=True;order.append(job[3]);now+=job[1]
    payload=struct.pack('<'+'i'*n,*order)
    return len(payload),payload
