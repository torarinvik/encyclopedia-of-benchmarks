#!/usr/bin/env python3
"""Validate wavelet-tree query implementations against a direct sequence oracle."""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import hashlib
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys

from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case
from wavelet_tree_oracle import MAX_INPUT_VALUES, expected_result

ALGORITHM = "wavelet_tree"


def corpus(workload: dict) -> tuple[str, int]:
    cases: dict[tuple[int, ...], int] = {}
    def include(values):
        packed = tuple(values)
        cases[packed] = expected_result(list(packed))
    include([1, 7, 0])
    for n in (1, 2, 3):
        for data in itertools.product((-1, 0, 1), repeat=n):
            queries = []
            for x in (-1, 0, 1):
                for end in range(-1, n): queries.append((0, x, end, 0, 0))
            for left in range(n):
                for right in range(left, n):
                    for k in range(right-left+1): queries.append((1,left,right,k,0))
                    for lo,hi in ((-1,0),(0,1),(-1,1)): queries.append((2,left,right,lo,hi))
            for q in range(min(2,len(queries))+1):
                for trace in itertools.product(queries, repeat=q):
                    include([n,*data,q,*(x for row in trace for x in row)])
    # Exercise the full declared parser length: 64 values plus 128 five-field queries.
    max_data = list(range(-32, 32))
    max_queries = [(1, 0, 63, k % 64, 0) for k in range(128)]
    max_input = [64, *max_data, 128, *(x for row in max_queries for x in row)]
    if len(max_input) != MAX_INPUT_VALUES:
        raise AssertionError("maximum wavelet-tree input length mismatch")
    include(max_input)
    rng = random.Random(20261016)
    for _ in range(800):
        n=rng.randrange(1,65); data=[rng.randrange(-1000,1001) for _ in range(n)]
        q=rng.randrange(0,129); ops=[]
        for _ in range(q):
            kind=rng.randrange(3)
            if kind==0: ops.append((0,rng.randrange(-1000,1001),rng.randrange(-1,n),0,0))
            else:
                a=rng.randrange(n); b=rng.randrange(a,n)
                if kind==1: ops.append((1,a,b,rng.randrange(b-a+1),0))
                else:
                    lo=rng.randrange(-1000,1001); hi=rng.randrange(lo,1001); ops.append((2,a,b,lo,hi))
        include([n,*data,q,*(x for row in ops for x in row)])
    for values in [(),(0,0,0),(65,),(1,0),(1,0,-1),(1,0,0,99,0,0,0),
                   (1,0,1,0,0,0),(1,0,1,2,0,0)]: include(values)
    for case in workload['cases']:
        values=encode_case(case, ALGORITHM)
        if expected_result(values)!=case['expected_result']: raise ValueError('workload oracle mismatch: '+case['id'])
        include(values)
    items=sorted(cases.items())
    records = ''.join(f"{len(v)} {e}"+(" "+" ".join(map(str,v)) if v else "")+"\n" for v,e in items)
    # Verify the ABI's null-input guard separately from malformed non-null arrays.
    null_canary = "NULL 1 -1\n"
    return records + null_canary, len(items) + 1


def verify(language, directory, compiler, data, count, workload):
    manifest=build(ALGORITHM,language,directory,compiler=compiler if language=='elisa' else None,
                   with_checker=True,family='i64_array_scalar')
    checker=manifest['binaries']['i64_array_scalar_check']['path']
    checked=subprocess.run([checker],input=f"{count}\n"+data,capture_output=True,text=True,timeout=180)
    if checked.returncode: raise RuntimeError(checked.stderr)
    if json.loads(checked.stdout)['cases_checked']!=count: raise RuntimeError('incomplete oracle check')
    records=directory/'verification-records.jsonl'; records.unlink(missing_ok=True)
    run=subprocess.run([sys.executable,str(ROOT/'benchmarks/run_i64_array_scalar.py'),'--build-manifest',str(directory/'build.json'),'--samples','1','--warmups','0','--repetitions','1','--output',str(records)],cwd=ROOT,capture_output=True,text=True,timeout=180)
    if run.returncode: raise RuntimeError(run.stdout+'\n'+run.stderr)
    rows=[json.loads(x) for x in records.read_text().splitlines()]
    if len(rows)!=len(workload['cases']): raise RuntimeError('workload records missing')
    for case,row in zip(workload['cases'],rows):
        vals=encode_case(case, ALGORITHM)
        if row['measurement']['observed_result']!=case['expected_result'] or row['workload']['input_values']!=vals: raise RuntimeError('workload mismatch '+case['id'])
    return {'language':language,'oracle_cases':count,'workload_records':len(rows),'source_sha256':manifest['source_sha256']}


def main():
    p=argparse.ArgumentParser(); p.add_argument('--languages',nargs='+',choices=EXTENSIONS,default=list(EXTENSIONS)); p.add_argument('--elisa-compiler'); p.add_argument('--jobs',type=int,default=3); p.add_argument('--build-dir',type=Path,default=ROOT/'build/i64_array_scalar/w/wavelet_tree'); a=p.parse_args()
    workload=json.loads((ROOT/'benchmarks/w/wavelet_tree/workload.json').read_text()); data,count=corpus(workload); out=[]; failures=[]
    a.build_dir.mkdir(parents=True,exist_ok=True)
    with ThreadPoolExecutor(max_workers=a.jobs) as pool:
        tasks={pool.submit(verify,l,a.build_dir/l,a.elisa_compiler,data,count,workload):l for l in a.languages}
        for task in as_completed(tasks):
            try: out.append(task.result()); print('PASS',tasks[task])
            except Exception as e: failures.append({'language':tasks[task],'error':str(e)}); print('FAIL',tasks[task],e,file=sys.stderr)
    report={'algorithm':ALGORITHM,'verified_at':dt.datetime.now(dt.timezone.utc).isoformat(),'platform':platform.platform(),'all_passed':not failures,'oracle_cases':count,'results':out,'failures':failures}
    (a.build_dir/'verification.json').write_text(json.dumps(report,indent=2)+'\n'); return int(bool(failures))

if __name__=='__main__': raise SystemExit(main())
