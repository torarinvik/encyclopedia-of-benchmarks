#!/usr/bin/env python3
"""Check seeded bounded t-SNE, including exponential underflow boundaries."""
import argparse
import itertools
import json
import math
from pathlib import Path
import random
import subprocess
from dimensionality_reduction_tsne_oracle import expected_result


def corpus():
    rows=[]
    def add(v,cap=3,null_input=False,null_output=False):
        result=None if null_input else expected_result(v)
        status=-1 if result is None else (-2 if null_output or cap<3 else 3)
        output=result if status>=0 else []
        rows.append(f'{len(v)} {status} {len(output)} {cap} {int(null_input)} {int(null_output)}\n'
                    +' '.join(format(x,'.17g') for x in v)+'\n'
                    +' '.join(format(x,'.17g') for x in output)+'\n')
    w=json.loads((Path(__file__).parent/'d/dimensionality_reduction_tsne/workload.json').read_text())
    for c in w['cases']:
        actual=expected_result(c['input_values'])
        if actual is None:
            if c['expected_result']!=-1:raise ValueError('oracle rejected fixture')
        elif len(actual)!=c['expected_result'] or any(not math.isclose(a,b,rel_tol=1e-10,abs_tol=1e-10) for a,b in zip(actual,c['expected_output'])):
            raise ValueError('fixture disagrees with oracle: '+c['id'])
        add(c['input_values'])
    for scale in (1e-12,.001,.1,1.,3.,7.,10.,20.,26.,27.,50.):
        for x in itertools.permutations((-scale,0.,scale)):
            add([1,3,*x])
    for x in [(0,0,0),(1,1,2),(0,1e-12,1),(99,99,100),(-100,-100,100),(-100,0,100)]:
        add([1,3,*x])
    rng=random.Random(174893)
    for i in range(250):
        x=[rng.uniform(-100,100) for _ in range(3)]
        if i%3==0:x=[z*.01 for z in x]
        v=[1,3,*x]
        for cap in (0,2,3,4):add(v,cap)
        add(v,null_input=True);add(v,null_output=True)
    valid=[1,3,0,1,3]
    for n in range(12):add((valid+[0]*12)[:n])
    for slot in range(5):
        for value in (math.nan,math.inf,-math.inf,-1e300,1e300):
            v=valid.copy();v[slot]=value;add(v)
    for slot in (0,1):
        for value in (-1,0,1.5,2,3.5,4):
            v=valid.copy();v[slot]=value;add(v)
    return f'{len(rows)} 1e-10 1e-10 5\n'+''.join(rows),len(rows)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--checker',action='append',required=True)
    args=p.parse_args();data,count=corpus()
    for checker in args.checker:
        r=subprocess.run([checker],input=data,capture_output=True,text=True,timeout=25)
        if r.returncode:raise RuntimeError(checker+': '+r.stderr)
        if json.loads(r.stdout)['cases_checked']!=count:raise RuntimeError('incomplete corpus')
        print(json.dumps({'checker':checker,'cases_checked':count}))
if __name__=='__main__':main()
