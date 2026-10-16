"""Oracle for bounded multivariate least-squares fit and prediction."""
import struct

MAX_INPUT_LENGTH = 33
MAX_OUTPUT_BYTES = 24

def expected_output(v):
    if not isinstance(v, (list, tuple)) or any(type(x) is not int or not -(2**63) <= x < 2**63 for x in v):
        return -1, b""
    if len(v) < 6: return -1, b""
    n, f, t = v[:3]
    if not 2 <= n <= 8 or f != 2 or not 1 <= t <= 3: return -1, b""
    end = 3 + n*(f+1)
    if end + t*f != len(v): return -1, b""
    train=[]; p=3
    for _ in range(n):
        row=v[p:p+f]; y=v[p+f]; p+=f+1
        if any(not -100 <= x <= 100 for x in row) or not -1000 <= y <= 1000: return -1,b""
        train.append((row,y))
    tests=[]
    for _ in range(t):
        row=v[p:p+f];p+=f
        if any(not -100 <= x <= 100 for x in row):return -1,b""
        tests.append(row)
    m=f+1
    a=[[0.0]*m for _ in range(m)]; b=[0.0]*m
    for x,y in train:
        z=[float(q) for q in x]+[1.0]
        for i in range(m):
            b[i]+=z[i]*y
            for j in range(m):a[i][j]+=z[i]*z[j]
    for col in range(m):
        pivot=max(range(col,m),key=lambda r:abs(a[r][col]))
        if abs(a[pivot][col]) < 1e-12:return -1,b""
        a[col],a[pivot]=a[pivot],a[col];b[col],b[pivot]=b[pivot],b[col]
        scale=a[col][col]
        for j in range(col,m):a[col][j]/=scale
        b[col]/=scale
        for r in range(m):
            if r==col:continue
            k=a[r][col]
            for j in range(col,m):a[r][j]-=k*a[col][j]
            b[r]-=k*b[col]
    out=[]
    for x in tests:out.append(sum(float(x[i])*b[i] for i in range(f))+b[f])
    return 8*t,struct.pack('<'+'d'*t,*out)
