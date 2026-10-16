#!/usr/bin/env python3
from __future__ import annotations
import argparse, datetime as dt, json, platform, shlex, subprocess
from pathlib import Path
from build_abi import ROOT, sha256_file
from diff_views_of_binary_tree_oracle import VIEWS, view

def main():
 p=argparse.ArgumentParser();p.add_argument('--build-manifest',required=True,type=Path);p.add_argument('--workload',type=Path);p.add_argument('--output',type=Path);p.add_argument('--samples',type=int);p.add_argument('--warmups',type=int);p.add_argument('--repetitions',type=int);a=p.parse_args();m=json.loads(a.build_manifest.read_text());wpath=a.workload or ROOT/'benchmarks/d/diff_views_of_binary_tree/workload.json';w=json.loads(wpath.read_text());tim=w['measurement'];samples=a.samples or tim['sample_count'];warm=a.warmups if a.warmups is not None else tim['warmup_rounds'];reps=a.repetitions or tim['repetitions_per_sample'];data=[str(len(w['cases']))]
 for c in w['cases']:
  expected=view(c['nodes'],c['root_index'],c['view'])
  if expected is None or expected!=c['expected_output_values'] or len(expected)!=c['expected_result']:raise ValueError('workload oracle mismatch: '+c['id'])
  data.append(f"{len(c['nodes'])} {c['root_index']} {VIEWS[c['view']]} {len(expected)}")
  data.extend(' '.join(map(str,r)) for r in c['nodes']);data.append(' '.join(map(str,expected)))
 exe=m['binaries']['tree_views_runner']['path'];run=subprocess.run([exe,str(samples),str(warm),str(reps)],input='\n'.join(data)+'\n',capture_output=True,text=True,check=True)
 rows=[json.loads(x) for x in run.stdout.splitlines()]; records=[]
 for c,row in zip(w['cases'],rows):
  records.append({'algorithm':m['algorithm'],'implementation':{'language':m['language'],'source_path':m['source_path'],'source_sha256':m['source_sha256'],'compiler':m['compiler'],'compiler_version':m['compiler_version'],'build_flags':m['build_flags'],'runner_source_sha256':m['binaries']['tree_views_runner']['harness_sha256'],'binary_sha256':m['binaries']['tree_views_runner']['sha256'],'build_command':'\n'.join(shlex.join(cmd) for cmd in m['commands'])},'workload':{'case_id':c['id'],'input_length':len(c['nodes']),'input_values':[v for r in c['nodes'] for v in r],'root_index':c['root_index'],'view':c['view'],'expected_output_values':c['expected_output_values']},'measurement':{'observed_result':row['result'],'samples_ns':row['samples_ns']}})
 out=a.output or ROOT/'results/diff_views_of_binary_tree'/m['language']/'records.jsonl';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(''.join(json.dumps(r)+'\n' for r in records));return 0
if __name__=='__main__':raise SystemExit(main())
