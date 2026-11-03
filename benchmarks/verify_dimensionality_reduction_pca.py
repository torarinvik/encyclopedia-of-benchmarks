#!/usr/bin/env python3
"""Qualify bounded PCA using an angle-based oracle and boundary inputs."""
import argparse
import json
import math
from pathlib import Path
import random
import subprocess
from dimensionality_reduction_pca_oracle import expected_result


def corpus():
    rows = []
    def add(v, capacity=8, null_input=False, null_output=False):
        result = None if null_input else expected_result(v)
        status = -1 if result is None else (-2 if null_output or capacity < len(result) else len(result))
        output = result if status >= 0 else []
        rows.append(f'{len(v)} {status} {len(output)} {capacity} {int(null_input)} {int(null_output)}\n'
                    + ' '.join(format(x, '.17g') for x in v) + '\n'
                    + ' '.join(format(x, '.17g') for x in output) + '\n')
    w = json.loads((Path(__file__).parent/'d/dimensionality_reduction_pca/workload.json').read_text())
    for c in w['cases']:
        actual = expected_result(c['input_values'])
        if actual is None or len(actual) != c['expected_result'] or any(not math.isclose(a,b,rel_tol=1e-10,abs_tol=1e-10) for a,b in zip(actual,c['expected_output'])):
            raise ValueError('fixture disagrees with oracle: '+c['id'])
        add(c['input_values'])
    # Both very small and very large covariance invalidate fixed iteration
    # counts initialized from the discriminant or inverse norm squared.
    for scale in (1e-12, 1e-6, 1e-3, 1.0, 1e3, 1e5):
        add([2,4,1,*[x*scale for x in (1,2,3,4,2,4,6,8)]])
    for scale in (1e-12, 1e-10, 1e-8):
        add([2,4,1,*[1+x*scale for x in (1,2,3,4)],*[2+y*scale for y in (2,4,6,8)]])
    rng = random.Random(274913)
    for n in range(2,9):
        for trial in range(100):
            scale = (1e-6, .001, 1., 100., 10000.)[trial%5]
            x = [rng.uniform(-8,8)*scale for _ in range(n)]
            y = [z*rng.uniform(.2,2)+rng.uniform(-1,1)*scale for z in x]
            v = [2,n,1,*x,*y]
            for cap in (0,n-1,n,n+1):add(v,cap)
            add(v,n,null_input=True)
            add(v,n,null_output=True)
    valid = [2,4,1,1,2,3,4,2,4,6,8]
    for length in range(25):add((valid+[0]*25)[:length])
    for slot in range(len(valid)):
        for z in (math.nan,math.inf,-math.inf,-1e300,1e300):
            v=valid.copy();v[slot]=z;add(v)
    for n in (-1,0,1,2,3,4.5,5,6,7,8,9):
        v=valid.copy();v[1]=n;add(v)
    add([2,2,1,0,0,0,0])
    add([2,2,1,0,1,1,0])
    return f'{len(rows)} 1e-10 1e-10 10\n'+''.join(rows),len(rows)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--checker',action='append',required=True)
    args=p.parse_args();data,count=corpus()
    for checker in args.checker:
        r=subprocess.run([checker],input=data,capture_output=True,text=True,timeout=25)
        if r.returncode:raise RuntimeError(checker+': '+r.stderr)
        if json.loads(r.stdout)['cases_checked'] != count:raise RuntimeError('incomplete corpus')
        print(json.dumps({'checker':checker,'cases_checked':count}))
if __name__=='__main__':main()
