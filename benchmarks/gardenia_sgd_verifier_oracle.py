"""Independent user/item-matrix verifier for bounded GARDENIA sequential SGD."""
from __future__ import annotations

import math


def expected_output(values, capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if (not isinstance(values, (list, tuple)) or type(output_is_null) is not bool
            or type(input_is_null) is not bool or (input_is_null and values)
            or (input_length is not None and input_length != len(values))
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return -1, []
    if input_is_null or len(values)<4 or any(type(v) not in (int,float) or not math.isfinite(float(v)) for v in values):
        return -1, []
    a=[float(v) for v in values]
    if any(a[i]!=math.trunc(a[i]) for i in range(4)):return -1, []
    users,items,m,k=(int(a[i]) for i in range(4));n=users+items
    if not 1<=users<=7 or not 1<=items<=7 or n>8 or not 1<=m<=24 or not 1<=k<=4 or len(a)!=5+users+2*m+n*k:return -1, []
    row_at=4;col_at=row_at+users+1;rating_at=col_at+m;factor_at=rating_at+m
    rows_raw=a[row_at:col_at];cols_raw=a[col_at:rating_at]
    if any(v!=math.trunc(v) for v in rows_raw+cols_raw):return -1, []
    rows=[int(v) for v in rows_raw];cols=[int(v) for v in cols_raw]
    if rows[0]!=0 or rows[-1]!=m or any(x<0 or x>m for x in rows) or any(x>y for x,y in zip(rows,rows[1:])) or any(x<0 or x>=items for x in cols):return -1, []
    ratings=a[rating_at:factor_at];factors=a[factor_at:]
    if any(v< -4 or v>4 for v in ratings) or any(v<0 or v>0.1 for v in factors):return -1, []
    required=n*k
    if output_is_null or capacity is not None and capacity<required:return -2, []
    users_x=[[factors[u*k+j] for j in range(k)] for u in range(users)]
    items_x=[[factors[(users+v)*k+j] for j in range(k)] for v in range(items)]
    for _ in range(3):
        error_by_user=[0.0]*users
        for u in range(users):
            for edge in range(rows[u],rows[u+1]):
                v=cols[edge];estimate=0.0
                for j in range(k):estimate+=users_x[u][j]*items_x[v][j]
                delta=ratings[edge]-estimate;error_by_user[u]+=delta*delta
                for j in range(k):
                    pu=users_x[u][j];pi=items_x[v][j]
                    users_x[u][j]+=0.00000035*(-0.001*pu+pi*delta)
                    items_x[v][j]+=0.00000035*(-0.001*pi+pu*delta)
        rmse=math.sqrt(sum(error_by_user)/m)
        if rmse<0.1:break
    result=[]
    for user in users_x:result.extend(user)
    for item in items_x:result.extend(item)
    return required,result
