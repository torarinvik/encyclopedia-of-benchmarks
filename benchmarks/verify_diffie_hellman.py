#!/usr/bin/env python3
"""Verify bounded Diffie–Hellman shared-secret ports against Python pow."""
from __future__ import annotations
import argparse, json, subprocess, sys
from pathlib import Path
from build_abi import EXTENSIONS, ROOT, build
from run_i64_array_scalar import encode_case

def oracle(v):
    if len(v)!=4:return -1
    g,a,b,p=v
    if p<2 or p>6_700_417 or g<1 or a<1 or b<1 or g>=p or a>=p or b>=p:return -1
    if any(p%d==0 for d in range(2,int(p**0.5)+1)):return -1
    return pow(pow(g,a,p),b,p)

def main():
    ap=argparse.ArgumentParser(description=__doc__); ap.add_argument('--languages',nargs='+',choices=EXTENSIONS,default=list(EXTENSIONS)); ap.add_argument('--elisa-compiler'); ap.add_argument('--build-dir',type=Path); args=ap.parse_args()
    workload=json.loads((ROOT/'benchmarks/d/diffie_hellman/workload.json').read_text()); cases=[c['input_values'] for c in workload['cases']]
    for c in workload['cases']:
        if oracle(c['input_values']) != c['expected_result']: raise ValueError(f"workload oracle mismatch: {c['id']}")
    cases += [[2,3,5,7],[2,3,4,15],[1,999999,1,1000000],[2,1,1,2],[6700418,1,1,6700421],[],[2,3,4]]
    records={tuple(v):oracle(v) for v in cases}; lines=[f'{len(records)}\n']
    for v,out in sorted(records.items()): lines.append(f'{len(v)} {out}'+(' '+' '.join(map(str,v)) if v else '')+'\n')
    directory=(args.build_dir or ROOT/'build/i64_array_scalar/d/diffie_hellman').resolve(); results=[]
    for lang in args.languages:
      try:
        d=directory/lang; manifest=build('diffie_hellman',lang,d,compiler=args.elisa_compiler if lang=='elisa' else None,with_checker=True,family='i64_array_scalar')
        proc=subprocess.run([manifest['binaries']['i64_array_scalar_check']['path']],input=''.join(lines),text=True,capture_output=True,timeout=180)
        if proc.returncode: raise RuntimeError(proc.stderr or proc.stdout)
        result=json.loads(proc.stdout)
        if result['cases_checked']!=len(records):raise RuntimeError('incomplete checker corpus')
        print(f'PASS diffie_hellman/{lang}: {len(records)} inputs')
        results.append({'language':lang,'status':'passed','oracle_cases':len(records)})
      except Exception as e:
        print(f'FAIL diffie_hellman/{lang}: {e}',file=sys.stderr);results.append({'language':lang,'status':'failed','error':str(e)})
    report={'algorithm':'diffie_hellman','all_passed':len(results)==len(args.languages) and all(r['status']=='passed' for r in results),'results':results}
    (directory/'verification.json').write_text(json.dumps(report,indent=2)+'\n'); return 0 if report['all_passed'] else 1
if __name__=='__main__':raise SystemExit(main())
