"""Unexecuted references for minimum-weight independent tree domination."""


def parse(values):
    if (not isinstance(values, (tuple, list)) or not 2 <= len(values) <= 129
            or any(type(value) is not int for value in values)):
        return None
    n=values[0]
    if not 1 <= n <= 64 or len(values) != 2*n:
        return None
    parents, weights=values[1:n], values[n:]
    if (any(not 0 <= parent < vertex for vertex, parent in enumerate(parents,1))
            or any(not 0 <= weight <= 1_000_000 for weight in weights)):
        return None
    return n, parents, weights


def expected(values):
    parsed=parse(values)
    if parsed is None:
        return -1
    n,parents,weights=parsed
    children=[[] for _ in range(n)]
    for child,parent in enumerate(parents,1):
        children[parent].append(child)
    inf=10**12
    selected,covered,waiting=[0]*n,[inf]*n,[0]*n
    for v in range(n-1,-1,-1):
        selected[v]=weights[v]+sum(min(covered[c],waiting[c]) for c in children[v])
        waiting[v]=min(inf,sum(covered[c] for c in children[v]))
        covered[v]=min((selected[chosen]+sum(min(selected[c],covered[c])
                        for c in children[v] if c!=chosen) for chosen in children[v]),default=inf)
    return min(selected[0],covered[0])


def brute_small(values):
    parsed=parse(values)
    if parsed is None:
        return -1
    n,parents,weights=parsed
    if n>16:
        raise ValueError("exhaustive reference is restricted to 16 vertices")
    neighborhoods=[1 << v for v in range(n)]
    for child,parent in enumerate(parents,1):
        neighborhoods[child] |= 1 << parent
        neighborhoods[parent] |= 1 << child
    best=sum(weights)
    for mask in range(1 << n):
        if (all(mask & neighborhood for neighborhood in neighborhoods)
                and all(not (mask >> child & 1 and mask >> parents[child-1] & 1)
                        for child in range(1,n))):
            best=min(best,sum(weights[v] for v in range(n) if mask >> v & 1))
    return best
