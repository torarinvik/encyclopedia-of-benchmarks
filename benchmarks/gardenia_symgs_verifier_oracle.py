"""Independent dense-row verifier for the bounded GARDENIA SymGS profile."""
from __future__ import annotations

import math


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or type(output_is_null) is not bool
            or type(input_is_null) is not bool or (input_is_null and values)
            or (input_length is not None and input_length != len(values))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values) < 3 or any(type(v) not in (int, float) or not math.isfinite(float(v)) for v in values):
        return -1, []
    a = [float(v) for v in values]
    if any(a[i] != math.trunc(a[i]) for i in range(3)):
        return -1, []
    n, m, c = map(int, a[:3])
    if not 1 <= n <= 8 or not 1 <= m <= 64 or not 1 <= c <= n or len(a) != 5 + 4*n + c + 2*m:
        return -1, []
    order_at=3;off_at=order_at+n;row_at=off_at+c+1;col_at=row_at+n+1;val_at=col_at+m;x_at=val_at+m;b_at=x_at+n
    def ints(start,count,limit):
        part=a[start:start+count]
        if len(part)!=count or any(v!=math.trunc(v) or v<0 or v>=limit for v in part): return None
        return [int(v) for v in part]
    order=ints(order_at,n,n);offsets=ints(off_at,c+1,n+1);rows=ints(row_at,n+1,m+1);cols=ints(col_at,m,n)
    if order is None or offsets is None or rows is None or cols is None or sorted(order)!=list(range(n)):
        return -1, []
    if offsets[0]!=0 or offsets[-1]!=n or any(x>=y for x,y in zip(offsets,offsets[1:])) or rows[0]!=0 or rows[-1]!=m or any(x>y for x,y in zip(rows,rows[1:])):
        return -1, []
    matrix=a[val_at:x_at];initial=a[x_at:b_at];rhs=a[b_at:b_at+n]
    if len(matrix)!=m or len(initial)!=n or len(rhs)!=n or any(abs(v)>4 for v in matrix+initial+rhs): return -1, []
    groups=[0]*n
    for color in range(c):
        for p in range(offsets[color],offsets[color+1]):groups[order[p]]=color
    dense=[[0.0]*n for _ in range(n)]
    for u in range(n):
        previous=-1;diag_count=0;offsum=0.0
        for edge in range(rows[u],rows[u+1]):
            v=cols[edge]
            if v<=previous:return -1, []
            previous=v;dense[u][v]=matrix[edge]
            if v==u:
                diag_count+=1
            else:
                if groups[u]==groups[v]:return -1, []
                offsum+=abs(matrix[edge])
        if diag_count!=1 or dense[u][u]<=offsum or dense[u][u]<=0:return -1, []
    for u in range(n):
        for v in range(n):
            if dense[u][v]!=dense[v][u]:return -1, []
    if output_is_null or capacity is not None and capacity<n:return -2, []
    x=list(initial)
    for color in (*range(c),*range(c-1,-1,-1)):
        for p in range(offsets[color],offsets[color+1]):
            u=order[p];total=0.0
            for v in range(n):
                if v!=u: total+=x[v]*dense[u][v]
            x[u]=(rhs[u]-total)/dense[u][u]
    return n,x
