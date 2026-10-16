#!/usr/bin/env python3
from __future__ import annotations
import argparse, concurrent.futures, datetime as dt, json, platform, subprocess, sys
from pathlib import Path
from build_abi import EXTENSIONS, ROOT, build, sha256_file
from diff_views_of_binary_tree_oracle import VIEWS, view
ALGORITHM='diff_views_of_binary_tree'
def corpus(workload):
 cases=list(workload['cases'])
 lines=[str(len(cases))]
 for c in cases:
  values=view(c['nodes'],c['root_index'],c['view'])
  if values is None or values!=c['expected_output_values'] or len(values)!=c['expected_result']:raise ValueError('bad workload '+c['id'])
  lines.append(f"{len(c['nodes'])} {c['root_index']} {VIEWS[c['view']]} {len(values)} {len(values)} {len(c['nodes'])}")
  lines.extend(' '.join(map(str,r)) for r in c['nodes']);lines.append(' '.join(map(str,values)))
 bad = [
  ('empty_bad_root', [], 0, 0, -1, len([])),
  ('bad_root', [[1,-1,-1]], 1, 0, -1, 1),
  ('bad_selector', [[1,-1,-1]], 0, 4, -1, 1),
  ('bad_child_index', [[1,1,-1]], 0, 0, -1, 1),
  ('multiple_parents', [[1,1,1],[2,-1,-1],[3,-1,-1]], 0, 2, -1, 3),
  ('unreachable_node', [[1,-1,-1],[2,-1,-1]], 0, 1, -1, 2),
  ('value_out_of_i32', [[1 << 40,-1,-1]], 0, 1, -1, 1),
  ('insufficient_capacity', [[1,-1,-1]], 0, 0, -2, 0),
 ]
 for _, nodes, root, selector, status, cap in bad:
  lines.append(f"{len(nodes)} {root} {selector} {status} 0 {cap}")
  lines.extend(' '.join(map(str,row)) for row in nodes)
 lines[0]=str(len(cases)+len(bad))
 return '\n'.join(lines)+'\n',len(cases)+len(bad)
def verify(lang,base,elisa,data,ncases,w):
 d=base/lang; m=build(ALGORITHM,lang,d,compiler=elisa if lang=='elisa' else None,with_checker=True,family='tree_views'); check=subprocess.run([m['binaries']['tree_views_check']['path']],input=data,capture_output=True,text=True,timeout=120,check=True)
 if json.loads(check.stdout)['cases_checked']!=ncases:raise ValueError('checker case count')
 out=d/'verification-records.jsonl';subprocess.run([sys.executable,str(ROOT/'benchmarks/run_diff_views_of_binary_tree.py'),'--build-manifest',str(d/'build.json'),'--samples','1','--warmups','0','--repetitions','1','--output',str(out)],cwd=ROOT,capture_output=True,text=True,timeout=120,check=True)
 rows=[json.loads(s) for s in out.read_text().splitlines()]
 if len(rows)!=len(w['cases']):raise ValueError('record count')
 for c,r in zip(w['cases'],rows):
  if r['implementation']['source_sha256']!=m['source_sha256'] or r['workload']['case_id']!=c['id'] or r['measurement']['observed_result']!=c['expected_result'] or not r['measurement']['samples_ns']:raise ValueError('record mismatch '+c['id'])
 return {'algorithm':ALGORITHM,'language':lang,'status':'passed','oracle_cases':ncases,'workload_records':len(rows),'source_sha256':m['source_sha256'],'build_manifest':str(d/'build.json'),'build_manifest_sha256':sha256_file(d/'build.json')}
def main():
 p=argparse.ArgumentParser();p.add_argument('--languages',nargs='+',choices=EXTENSIONS,default=list(EXTENSIONS));p.add_argument('--elisa-compiler');p.add_argument('--jobs',type=int,default=3);p.add_argument('--build-dir',type=Path,default=ROOT/'build/diff_views_of_binary_tree');a=p.parse_args();w=json.loads((ROOT/'benchmarks/d/diff_views_of_binary_tree/workload.json').read_text());data,n=corpus(w);a.build_dir.mkdir(parents=True,exist_ok=True);(a.build_dir/'corpus.txt').write_text(data);results=[]
 with concurrent.futures.ThreadPoolExecutor(max_workers=a.jobs) as pool:
  futures={pool.submit(verify,l,a.build_dir,a.elisa_compiler,data,n,w):l for l in a.languages}
  for f in concurrent.futures.as_completed(futures):
   try:r=f.result();results.append(r);print(f"PASS {ALGORITHM}/{r['language']}: {n} view cases")
   except Exception as e:print(f"FAIL {ALGORITHM}/{futures[f]}: {e}",file=sys.stderr);return 1
 report={'algorithm':ALGORITHM,'verified_at':dt.datetime.now(dt.timezone.utc).isoformat(),'platform':platform.platform(),'results':results};(a.build_dir/'verification.json').write_text(json.dumps(report,indent=2)+'\n');return 0
if __name__=='__main__':raise SystemExit(main())
