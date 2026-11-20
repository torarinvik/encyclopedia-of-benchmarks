"""Unverified logarithmic angular-minimum search for a Chan subgroup hull.

The query is an extreme point of the full input and is external to this group.
All rays from it to the group are therefore contained in an open half-plane.
The subgroup is a strictly convex CCW polygon in cyclic storage order.
"""


def wrapping_candidate(polygon, query):
    def cross(a, b):
        return (a[0]-query[0])*(b[1]-query[1]) - (a[1]-query[1])*(b[0]-query[0])

    size = len(polygon)
    if size == 0:
        raise ValueError("empty subgroup")
    if size == 1:
        return polygon[0]
    lo, hi = 0, size - 1
    while lo < hi:
        middle = (lo + hi) // 2
        if cross(polygon[middle], polygon[hi]) > 0:
            hi = middle
        else:
            lo = middle + 1
    return polygon[lo]
