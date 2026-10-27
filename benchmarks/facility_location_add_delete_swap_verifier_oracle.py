"""Independent set-list verifier for facility-location local search."""

from __future__ import annotations

import struct
from collections.abc import Sequence


def _obj(n: int, m: int, metric: list[int], opening: list[int], centers: tuple[int, ...]) -> int:
    q = n + m
    answer = sum(opening[c] for c in centers)
    for u in range(n):
        answer += min(metric[u*q+n+c] for c in centers)
    return answer


def _lex(a: tuple[int, ...], b: tuple[int, ...]) -> bool:
    return a < b


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int or input_length < 0)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if len(values) < 4 or len(values) > 75 or any(type(x) is not int or not -(1<<63)<=x<(1<<63) for x in values):
        return -1, b""
    n,m=values[0],values[1]
    if not 1<=n<=7 or not 1<=m<=7 or n+m>8:return -1,b""
    q=n+m
    if len(values)!=2+q*q+m+1:return -1,b""
    metric=list(values[2:2+q*q]); fees=list(values[2+q*q:2+q*q+m]); mask=values[-1]
    if any(not 0<=v<=1000 for v in metric+fees) or not 0<mask<(1<<m):return -1,b""
    for a in range(q):
        if metric[a*q+a]!=0:return -1,b""
        for b in range(q):
            if metric[a*q+b] != metric[b*q+a] or (a!=b and metric[a*q+b]<=0):return -1,b""
            for c in range(q):
                if metric[a*q+b]>metric[a*q+c]+metric[c*q+b]:return -1,b""
    if not 0<=mask<(1<<m):return -1,b""
    centers=tuple(j for j in range(m) if mask&(1<<j))
    score=_obj(n,m,metric,fees,centers)
    while True:
        best=centers; best_score=score
        open_set=set(centers)
        candidates=[]
        for add in range(m):
            if add not in open_set:candidates.append(tuple(sorted((*centers,add))))
        if len(centers)>1:
            for drop in centers:
                candidates.append(tuple(x for x in centers if x!=drop))
        for drop in centers:
            for add in range(m):
                if add not in open_set:
                    candidates.append(tuple(sorted((set(centers)-{drop})|{add})))
        for candidate in candidates:
            candidate_score=_obj(n,m,metric,fees,candidate)
            if candidate_score<score and (candidate_score<best_score or candidate_score==best_score and _lex(candidate,best)):
                best,best_score=candidate,candidate_score
        if best_score*10>=score*9:break
        centers,score=best,best_score
    assigned=tuple(min(centers,key=lambda c:(metric[u*q+n+c],c)) for u in range(n))
    output=struct.pack('<'+'q'*(2+len(centers)+n),score,len(centers),*centers,*assigned)
    if output_is_null or capacity is not None and capacity<len(output):return -2,b""
    return len(output),output
