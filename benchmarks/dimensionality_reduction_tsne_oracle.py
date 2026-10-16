"""Independent deterministic oracle for the tiny seeded Python t-SNE slice."""
import math

INITIAL = [3.0471707975443136e-05, -0.00010399841062404956, 7.504511958064573e-05]
PERPLEXITY = 1.5
LEARNING_RATE = 10.0
ITERATIONS = 5


def expected_result(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 5
            or any(type(v) not in (int, float) or not math.isfinite(float(v)) for v in values)):
        return None
    if values[0] != 1 or values[1] != 3 or any(abs(float(v)) > 100 for v in values[2:]):
        return None
    x = [float(v) for v in values[2:]]
    distances = [[(x[i]-x[j])**2 for j in range(3)] for i in range(3)]
    conditional = [[0.0]*3 for _ in range(3)]
    for i in range(3):
        beta_min, beta_max, beta = -math.inf, math.inf, 1.0
        for _ in range(50):
            exps = [math.exp(-distances[i][j]*beta) for j in range(3)]
            exps[i] = 0.0
            total = sum(exps)
            if total == 0.0:
                conditional[i] = [0.0]*3
                break
            probabilities = [v/total for v in exps]
            entropy = -sum(p*math.log2(p+1e-12) for p in probabilities)
            current = 2.0**entropy
            if abs(current-PERPLEXITY) < 1e-5:
                conditional[i] = probabilities
                break
            if current > PERPLEXITY:
                beta_min = beta
                beta = beta*2.0 if math.isinf(beta_max) else (beta+beta_max)/2.0
            else:
                beta_max = beta
                beta = beta/2.0 if math.isinf(beta_min) else (beta+beta_min)/2.0
        else:
            conditional[i] = probabilities
    high = [[max((conditional[i][j]+conditional[j][i])/6.0,1e-12)
             for j in range(3)] for i in range(3)]
    y = INITIAL[:]
    momentum = [0.0]*3
    for _ in range(ITERATIONS):
        low_denom = [[math.inf if i==j else 1.0+(y[i]-y[j])**2 for j in range(3)] for i in range(3)]
        low = [[0.0 if i==j else 1.0/low_denom[i][j] for j in range(3)] for i in range(3)]
        total_low = sum(sum(row) for row in low)
        if total_low == 0.0:
            low = [[0.0 if i==j else 1.0/6.0 for j in range(3)] for i in range(3)]
        else:
            low = [[v/total_low for v in row] for row in low]
        low = [[max(v,1e-12) for v in row] for row in low]
        gradient = [0.0]*3
        for i in range(3):
            for j in range(3):
                diff = y[i]-y[j]
                gradient[i] += (high[i][j]-low[i][j])*(1.0/low_denom[i][j])*diff
            gradient[i] *= 4.0
        for i in range(3):
            momentum[i] = 0.5*momentum[i]-LEARNING_RATE*gradient[i]
            y[i] += momentum[i]
    return y
