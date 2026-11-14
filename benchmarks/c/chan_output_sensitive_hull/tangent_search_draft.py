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
    if size == 2:
        return polygon[0] if cross(polygon[0], polygon[1]) > 0 else polygon[1]
    initial_up = cross(polygon[0], polygon[1]) > 0
    lo, hi = 0, size
    while lo < hi:
        middle = (lo + hi) // 2
        previous = (middle - 1) % size
        following = (middle + 1) % size
        less_previous = cross(polygon[middle], polygon[previous]) > 0
        less_following = cross(polygon[middle], polygon[following]) > 0
        if less_previous and less_following:
            return polygon[middle]
        before_anchor = middle != 0 and cross(polygon[middle], polygon[0]) > 0
        after_anchor = middle != 0 and cross(polygon[0], polygon[middle]) > 0
        search_left = (less_following and before_anchor) if initial_up else (less_following or after_anchor)
        if search_left:
            hi = middle
        else:
            lo = middle + 1
    raise ValueError("supporting vertex not found under tangent preconditions")
