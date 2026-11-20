"""Unexecuted exact reference for small tree radius-domination instances."""
from collections import deque


def parse(values):
    if (not isinstance(values,(tuple,list)) or not 2 <= len(values) <= 66
            or any(type(value) is not int for value in values)):
        return None
    n,radius=values[:2]
    if not 1 <= n <= 64 or not 0 <= radius <= 63 or len(values)!=n+1:
        return None
    parents=values[2:]
    if any(not 0 <= parent < v for v,parent in enumerate(parents,1)):
        return None
    return n,radius,parents


def brute_small(values):
    parsed=parse(values)
    if parsed is None:
        return -1
    n,radius,parents=parsed
    if n>16:
        raise ValueError("exhaustive reference is restricted to 16 vertices")
    graph=[[] for _ in range(n)]
    for v,p in enumerate(parents,1):
        graph[v].append(p)
        graph[p].append(v)
    cover=[]
    for source in range(n):
        distance=[-1]*n
        distance[source]=0
        queue=deque([source])
        while queue:
            vertex=queue.popleft()
            if distance[vertex]==radius:
                continue
            for neighbor in graph[vertex]:
                if distance[neighbor]<0:
                    distance[neighbor]=distance[vertex]+1
                    queue.append(neighbor)
        cover.append(sum(1 << v for v in range(n) if distance[v]>=0))
    full=(1 << n)-1
    best=n
    for mask in range(1 << n):
        if mask.bit_count() >= best:
            continue
        covered=0
        for v in range(n):
            if mask >> v & 1:
                covered |= cover[v]
        if covered==full:
            best=mask.bit_count()
    return best


def expected(values):
    parsed=parse(values)
    if parsed is None:
        return -1
    n,radius,parents=parsed
    graph=[[] for _ in range(n)]
    depth=[0]*n
    for v,p in enumerate(parents,1):
        graph[v].append(p)
        graph[p].append(v)
        depth[v]=depth[p]+1
    covered=[False]*n
    answer=0
    while not all(covered):
        vertex=min((v for v in range(n) if not covered[v]),key=lambda v:(-depth[v],v))
        center=vertex
        for _ in range(radius):
            if center==0:
                break
            center=parents[center-1]
        distance=[-1]*n
        distance[center]=0
        queue=deque([center])
        while queue:
            v=queue.popleft()
            covered[v]=True
            if distance[v]==radius:
                continue
            for u in graph[v]:
                if distance[u]<0:
                    distance[u]=distance[v]+1
                    queue.append(u)
        answer+=1
    return answer
