"""Exhaustive supporting-vertex oracle for Chan tangent-search development.

The polygon is a counterclockwise strictly convex hull with one or more
vertices. The query is either a polygon vertex or outside the polygon, and no
three distinct points among the query and vertices are collinear. Returns the
candidate whose directed ray leaves all other vertices on its left, or None
when the polygon contains only the query. This quadratic check is deliberately
independent of any eventual logarithmic tangent search.
"""


def wrapping_candidate(polygon, query):
    def cross(a, b, c):
        return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])

    matches = [candidate for candidate in polygon if candidate != query
               and all(cross(query, candidate, other) >= 0 for other in polygon)]
    if not matches:
        if len(polygon) == 1 and polygon[0] == query:
            return None
        raise ValueError("no supporting vertex: tangent preconditions were violated")
    if len(matches) != 1:
        raise ValueError("ambiguous supporting vertex: general position was violated")
    return matches[0]
