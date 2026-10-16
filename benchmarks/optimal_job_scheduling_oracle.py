"""Runtime oracle for precedence-ordered jobs on multiple machines."""
MAX_INPUT_LENGTH = 194
MAX_OUTPUT_BYTES = 2048

def expected_output(values):
    if (not isinstance(values,(list,tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH
            or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in values)):
        return -1,b""
    processes,machines=values[:2]
    if not 1<=processes<=16 or not 1<=machines<=8 or len(values)!=2+processes*machines+machines*machines:
        return -1,b""
    raw=values[2:]
    if any(x<0 or x>1000 for x in raw):return -1,b""
    run=raw[:processes*machines];transfer=raw[processes*machines:]
    cost=[[0]*machines for _ in range(processes)]
    cost[0]=run[:machines]
    for i in range(1,processes):
        for j in range(machines):
            cost[i][j]=min(cost[i-1][k]+transfer[k*machines+j]+run[i*machines+j] for k in range(machines))
    output='\n'.join(','.join(map(str,row)) for row in cost).encode('ascii')
    return (len(output),output) if len(output)<=MAX_OUTPUT_BYTES else (-1,b"")
