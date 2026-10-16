#!/usr/bin/env python3
"""Verify unrolled linked-list ports against the deterministic chunk oracle."""
from __future__ import annotations
import argparse, json, random, subprocess, tempfile
from pathlib import Path
from build_abi import EXTENSIONS, ROOT, build
from unrolled_linked_list_oracle import expected_result

ALGORITHM = "unrolled_linked_list"
def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--languages',nargs='+',choices=EXTENSIONS,default=list(EXTENSIONS))
    parser.add_argument('--elisa-compiler')
    args=parser.parse_args()
    workload=json.loads((ROOT/'benchmarks/u/unrolled_linked_list/workload.json').read_text())
    cases={tuple(c['input_values']) for c in workload['cases']}
    for n in range(9):
        for x in (-2,0,1): cases.add((x,)*n)
    rng=random.Random(20261016)
    for _ in range(384): cases.add(tuple(rng.randrange(-100,101) for _ in range(rng.randrange(1025))))
    cases.add(tuple(range(1024))); cases.add(tuple([1000000]*1024)); cases.add(tuple([1000001]))
    corpus=[f'{len(cases)}\n']
    for values in sorted(cases):
        e=expected_result(list(values)); suffix='' if not values else ' '+' '.join(map(str,values))
        corpus.append(f'{len(values)} {e}{suffix}\n')
    data=''.join(corpus); errors=[]
    for lang in args.languages:
        directory=ROOT/'build/i64_array_scalar/u/unrolled_linked_list'/lang
        directory.mkdir(parents=True,exist_ok=True)
        try:
            manifest=build(ALGORITHM,lang,ROOT/lang/'u',compiler=args.elisa_compiler if lang=='elisa' else None,with_checker=True,family='i64_array_scalar')
            checked=subprocess.run([manifest['binaries']['i64_array_scalar_check']['path']],input=data,text=True,capture_output=True,timeout=120)
            if checked.returncode: raise RuntimeError(checked.stderr or checked.stdout or f"checker exit {checked.returncode}")
            count=json.loads(checked.stdout)['cases_checked']
            if count!=len(cases): raise RuntimeError(f'checker covered {count} of {len(cases)} cases')
            records_path=Path(tempfile.mkdtemp(prefix='unrolled-list-'))/'verification-records.jsonl'
            recorded=subprocess.run(['python3',str(ROOT/'benchmarks/run_i64_array_scalar.py'),'--build-manifest',str(ROOT/lang/'u'/'build.json'),'--samples','1','--warmups','0','--repetitions','1','--output',str(records_path)],cwd=ROOT,text=True,capture_output=True,timeout=120)
            if recorded.returncode: raise RuntimeError(recorded.stdout+recorded.stderr)
            records=[json.loads(line) for line in records_path.read_text().splitlines()]
            if len(records)!=len(workload['cases']): raise RuntimeError('recorder did not emit every workload case')
            for case,record in zip(workload['cases'],records):
                if record['algorithm']!=ALGORITHM or record['workload']['input_values']!=case['input_values'] or record['measurement']['observed_result']!=case['expected_result']:
                    raise RuntimeError(f"workload record mismatch: {case['id']}")
            print(f'PASS {lang}: {count} oracle cases and {len(records)} workload records')
        except Exception as exc:
            errors.append((lang,str(exc))); print(f'FAIL {lang}: {exc}')
    return int(bool(errors))
if __name__=='__main__': raise SystemExit(main())
