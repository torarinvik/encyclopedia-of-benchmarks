"""Reference 2-SAT solver for the bounded signed-literal contract."""
MAX_VARIABLES = 40
MAX_CLAUSES = 2047
MAX_INPUT_LENGTH = 2 + 2 * MAX_CLAUSES

def expected_output(values):
    if not isinstance(values, (list, tuple)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return -1, b""
    n, m = values[0], values[1]
    if type(n) is not int or type(m) is not int or not 0 <= n <= MAX_VARIABLES or not 0 <= m <= MAX_CLAUSES or len(values) != 2 + 2*m:
        return -1, b""
    if any(type(x) is not int or x == 0 or abs(x) > n for x in values[2:]):
        return -1, b""
    size = 2*n
    graph = [[] for _ in range(size)]
    rev = [[] for _ in range(size)]
    def lit(x):
        v = 2*(abs(x)-1)
        return v + (x < 0)
    for a,b in zip(values[2::2], values[3::2]):
        x,y=lit(a),lit(b)
        for u,v in ((x^1,y),(y^1,x)):
            graph[u].append(v); rev[v].append(u)
    seen=[False]*size; order=[]
    def first(v):
        seen[v]=True
        for w in graph[v]:
            if not seen[w]: first(w)
        order.append(v)
    for v in range(size):
        if not seen[v]: first(v)
    comp=[-1]*size
    def second(v,c):
        comp[v]=c
        for w in rev[v]:
            if comp[w]<0: second(w,c)
    c=0
    for v in reversed(order):
        if comp[v]<0: second(v,c); c+=1
    if any(comp[2*i] == comp[2*i+1] for i in range(n)):
        return 1, bytes([0])
    # Kosaraju emits source components first with this traversal order.
    assignment=[int(comp[2*i] > comp[2*i+1]) for i in range(n)]
    return len(assignment)+1, bytes([1,*assignment])
