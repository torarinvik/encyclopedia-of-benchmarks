#!/usr/bin/env python3
"""Check linked list traces against an independent Python-list oracle."""
from __future__ import annotations
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import datetime as dt
import itertools
import json
from pathlib import Path
import platform
import random
import subprocess
import sys
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from run_i64_array_scalar import encode_case

ALGORITHM='linked_list'
INVALID=-1
CAPACITY=256
MAX_OPERATIONS=512

def oracle(values: list[int]) -> int:
    if len(values)>2*MAX_OPERATIONS or len(values)%2: return INVALID
    items=[]; checksum=0; operation_count=len(values)//2
    for operation in range(operation_count):
        opcode,payload=values[2*operation:2*operation+2]
        if opcode in (0,1):
            if not -1_000_000<=payload<=1_000_000 or len(items)==CAPACITY: return INVALID
            if opcode==0: items.append(payload)
            else: items.insert(0,payload)
            continue
        if opcode in (2,3,6) and payload!=0: return INVALID
        if opcode in (4,5) and not -1_000_000<=payload<=1_000_000: return INVALID
        if opcode==2:
            if not items: return INVALID
            observed=items.pop(0)
        elif opcode==3:
            if not items: return INVALID
            observed=items.pop()
        elif opcode==4:
            observed=int(payload in items)
            if observed: items.remove(payload)
        elif opcode==5: observed=int(payload in items)
        elif opcode==6: observed=len(items)
        else: return INVALID
        checksum+=(operation+1)*(observed+1_000_000)
    for index,value in enumerate(items):
        checksum+=(operation_count+index+1)*(value+1_000_000)
    return checksum

def checker_corpus(cases: dict[tuple[int,...],int])->str:
    lines=[f'{len(cases)}\n']
    for values in sorted(cases):
        expected=oracle(list(values)); suffix='' if not values else ' '+' '.join(map(str,values))
        lines.append(f'{len(values)} {expected}{suffix}\n')
    return ''.join(lines)

def verify(language: str,directory: Path,elisa_compiler: str|None,data: str,case_count: int,workload: dict)->dict:
    manifest=build(ALGORITHM,language,directory,compiler=elisa_compiler if language=='elisa' else None,with_checker=True,family='i64_array_scalar')
    checker=manifest['binaries']['i64_array_scalar_check']['path']
    checked=subprocess.run([checker],input=data,capture_output=True,text=True,timeout=120)
    if checked.returncode: raise RuntimeError(f'array scalar C ABI check failed: {checked.stderr}')
    if json.loads(checked.stdout)['cases_checked']!=case_count: raise RuntimeError('checker did not consume complete oracle corpus')
    records_path=directory/'verification-records.jsonl'; records_path.unlink(missing_ok=True)
    recorded=subprocess.run([sys.executable,str(ROOT/'benchmarks/run_i64_array_scalar.py'),'--build-manifest',str(directory/'build.json'),'--samples','1','--warmups','0','--repetitions','1','--output',str(records_path)],cwd=ROOT,capture_output=True,text=True,timeout=120)
    if recorded.returncode: raise RuntimeError(f'workload/recorder check failed: {recorded.stdout}\n{recorded.stderr}')
    records=[json.loads(line) for line in records_path.read_text().splitlines()]
    if len(records)!=len(workload['cases']): raise RuntimeError('unexpected workload record count')
    for case,record in zip(workload['cases'],records):
        values=encode_case(case); expected=oracle(values)
        if (expected!=case['expected_result'] or record['algorithm']!=ALGORITHM or record['implementation']['language']!=language or record['implementation']['source_sha256']!=manifest['source_sha256'] or record['workload']['input_length']!=len(values) or record['workload']['input_values']!=values or record['workload']['expected_result']!=expected or record['measurement']['observed_result']!=expected or len(record['measurement']['samples_ns'])!=1):
            raise RuntimeError(f'recorded result/provenance mismatch: {case["id"]}')
    return {'algorithm':ALGORITHM,'language':language,'status':'passed','oracle_cases':case_count,'source_sha256':manifest['source_sha256'],'workload_records':len(records),'build_manifest':str(directory/'build.json'),'build_manifest_sha256':sha256_file(directory/'build.json'),'recorder_output':str(records_path),'recorder_output_sha256':sha256_file(records_path)}

def main()->int:
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--languages',nargs='+',choices=EXTENSIONS,default=list(EXTENSIONS));parser.add_argument('--elisa-compiler');parser.add_argument('--jobs',type=int,default=3);parser.add_argument('--build-dir',type=Path,default=ROOT/'build/i64_array_scalar/l/linked_list');args=parser.parse_args()
    if args.jobs<1 or len(set(args.languages))!=len(args.languages): parser.error('jobs must be positive and language selections unique')
    directory=args.build_dir.resolve();directory.mkdir(parents=True,exist_ok=True)
    workload=json.loads((ROOT/'benchmarks/l/linked_list/workload.json').read_text())
    cases:dict[tuple[int,...],int]={}
    token_types=((0,-1),(0,0),(0,1),(1,-1),(1,0),(1,1),(2,0),(3,0),(4,-1),(4,0),(4,1),(5,-1),(5,0),(5,1),(6,0))
    for n in range(4):
        for sequence in itertools.product(token_types,repeat=n):
            packed=tuple(value for pair in sequence for value in pair);cases[packed]=oracle(list(packed))
    rng=random.Random(20261014)
    for _ in range(768):
        op_count=rng.randrange(MAX_OPERATIONS+1);items=[];packed=[]
        for _step in range(op_count):
            choices=[4,5,6]
            if len(items)<CAPACITY: choices.extend((0,1))
            if items: choices.extend((2,3))
            op=rng.choice(choices)
            if op in (0,1):
                value=rng.randrange(-1_000_000,1_000_001);packed.extend((op,value))
                if op==0: items.append(value)
                else: items.insert(0,value)
            elif op in (4,5):
                value=rng.randrange(-1_000_000,1_000_001);packed.extend((op,value))
                if op==4 and value in items: items.remove(value)
            else:
                packed.extend((op,0))
                if op==2: items.pop(0)
                elif op==3: items.pop()
        key=tuple(packed);cases[key]=oracle(list(key))
    for _ in range(512):
        length=rng.randrange(65);key=tuple(rng.choice((-1,0,1,2,3,4,5,6,7,1_000_001)) for _ in range(length));cases[key]=oracle(list(key))
    full=[v for i in range(CAPACITY) for v in (0,i)];cases[tuple(full)]=oracle(full)
    drain=full+[v for _ in range(CAPACITY) for v in (3,0)];cases[tuple(drain)]=oracle(drain)
    for case in workload['cases']:
        packed=tuple(encode_case(case));expected=oracle(list(packed))
        if expected!=case['expected_result']: parser.error(f'workload oracle mismatch: {case["id"]}')
        cases[packed]=expected
    data=checker_corpus(cases);results=[];failures=[]
    with ThreadPoolExecutor(max_workers=args.jobs) as pool:
        jobs={pool.submit(verify,lang,directory/lang,args.elisa_compiler,data,len(cases),workload):lang for lang in args.languages}
        for job in as_completed(jobs):
            lang=jobs[job]
            try: result=job.result()
            except Exception as exc:
                failures.append({'language':lang,'error':str(exc)});print(f'FAIL {lang}: {exc}',file=sys.stderr,flush=True);continue
            results.append(result);print(f'PASS {lang}: {len(cases)} oracle traces, {result["workload_records"]} workload records',flush=True)
    report={'algorithm':ALGORITHM,'verified_at':dt.datetime.now(dt.timezone.utc).isoformat(),'platform':platform.platform(),'all_passed':not failures,'oracle_cases':len(cases),'results':sorted(results,key=lambda x:x['language']),'failures':failures}
    report_path=directory/'verification.json';report_path.write_text(json.dumps(report,indent=2)+'\n');print(f'verification report: {report_path}')
    return 0 if not failures and len(results)==len(args.languages) else 1
if __name__=='__main__': raise SystemExit(main())
