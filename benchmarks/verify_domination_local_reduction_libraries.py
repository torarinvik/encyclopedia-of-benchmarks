import argparse,ctypes,itertools,random,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1];sys.path.insert(0,str(root/'benchmarks'))
from domination_local_reduction_oracle import evaluate
from domination_local_reduction_verifier_oracle import verify
parser=argparse.ArgumentParser(description='Compare implementations with two graph oracles.')
parser.add_argument('libraries', nargs='+', help='shared libraries exporting domination_local_reduction')
args=parser.parse_args()
libs={x:ctypes.CDLL(str(Path(x).resolve())) for x in args.libraries}
func={x:l.domination_local_reduction for x,l in libs.items()}
for f in func.values():f.argtypes=[ctypes.POINTER(ctypes.c_int64),ctypes.c_size_t,ctypes.POINTER(ctypes.c_uint8),ctypes.c_size_t];f.restype=ctypes.c_int64
count=0;outputs=0
cases=[[],[0,0,0],[1,0,0],[2,1,0,0,1],[2,1,0,1,0],[2,2,0,0,1,0,1],[13,0,0],[1,-1,0],[2,1,2,0,1]]
for n in range(1,6):
 edges=list(itertools.combinations(range(n),2))
 for mask in range(1<<len(edges)):
  selected=[e for j,e in enumerate(edges) if mask>>j&1]
  for pivot in range(n):cases.append([n,len(selected),pivot,*[v for e in selected for v in e]])
rng=random.Random(20261106)
for _ in range(500):
 n=rng.randrange(6,13);edges=[e for e in itertools.combinations(range(n),2) if rng.randrange(2)];cases.append([n,len(edges),rng.randrange(n),*[v for e in edges for v in e]])
for vals in cases:
 ref=evaluate(vals);assert verify(vals)==ref,(vals,ref,verify(vals))
 arr=(ctypes.c_int64*max(1,len(vals)))(*vals)
 for name,f in func.items():
  buf=(ctypes.c_uint8*208)(*[0xa5]*208);r=f(arr,len(vals),buf,200)
  if r!=ref[0] or (r>=0 and bytes(buf[:r])!=ref[1]) or any(x!=0xa5 for x in buf[max(0,r):]): raise AssertionError((name,vals,ref,r,bytes(buf[:max(0,r)]).hex()))
  if ref[0]>0:
   for cap,null in ((ref[0]-1,False),(200,True)):
    buf=(ctypes.c_uint8*208)(*[0xa5]*208);r=f(arr,len(vals),None if null else buf,cap)
    if r!=-2 or any(x!=0xa5 for x in buf):raise AssertionError((name,'capacity',vals,r))
  count+=1
 for f in func.values():
  buf=(ctypes.c_uint8*208)(*[0xa5]*208)
  if f(None,3,buf,200)!=-1 or any(x!=0xa5 for x in buf):raise AssertionError('null')
 outputs+=1
print(f'PASS {outputs} cases, {count} implementation comparisons, null/capacity canaries')
