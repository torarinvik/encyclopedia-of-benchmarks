"""Oracle for the bounded 1/7/30-day ticket dynamic program."""
MAX_INPUT_LENGTH=369
def expected_result(values):
    if not isinstance(values,(list,tuple)) or not 4<=len(values)<=MAX_INPUT_LENGTH:return -1
    if any(type(x)is not int or not -(2**63)<=x<2**63 for x in values):return -1
    n=values[0]
    if not 0<=n<=365 or len(values)!=n+4:return -1
    days=values[1:n+1];costs=values[n+1:]
    if any(not 1<=d<=365 for d in days) or len(set(days))!=n:return -1
    if any(not 0<=c<=1_000_000 for c in costs):return -1
    travel=set(days);dp=[0]*396
    for day in range(365,0,-1):
        if day not in travel:dp[day]=dp[day+1]
        else:dp[day]=min(costs[0]+dp[min(day+1,395)],costs[1]+dp[min(day+7,395)],costs[2]+dp[min(day+30,395)])
    return dp[1]
