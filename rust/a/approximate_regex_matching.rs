/// Layered edit-distance shortest paths over a supplied literal NFA.
#[no_mangle]
pub extern "C" fn approximate_regex_matching(x:*const i64,len:usize,out:*mut u8,cap:usize)->i64{
 if x.is_null(){return -2}if len<6||len>66{return -1}let a=unsafe{std::slice::from_raw_parts(x,len)};
 let (sv,ev,tv,kv,stv,av)=(a[0],a[1],a[2],a[3],a[4],a[5]);
 if sv<2||sv>8||ev<1||ev>16||tv<0||tv>12||kv<0||kv>3||stv<0||av<0||stv>=sv||av>=sv||stv==av{return -1}
 let (s,e,t,k,start,accept)=(sv as usize,ev as usize,tv as usize,kv as usize,stv as usize,av as usize);let ts=6+3*e;if len!=ts+t{return -1}
 let mut from=[0usize;16];let mut to=[0usize;16];let mut label=[0u8;16];
 for i in 0..e{let (u,v,c)=(a[6+3*i],a[7+3*i],a[8+3*i]);if u<0||u>=sv||v<0||v>=sv||c<1||c>127{return -1}from[i]=u as usize;to[i]=v as usize;label[i]=c as u8;for j in 0..i{if from[i]==from[j]&&to[i]==to[j]&&label[i]==label[j]{return -1}}}
 if a[ts..].iter().any(|c|*c<1||*c>127){return -1}if cap<t||(t>0&&out.is_null()){return -2}
 let inf=k+1;let mut cur=[inf;8];let mut next=[inf;8];
 for pos in 0..t{cur[start]=0;for _ in 0..s-1{let mut changed=false;for i in 0..e{if cur[from[i]]<inf&&cur[from[i]]+1<cur[to[i]]{cur[to[i]]=cur[from[i]]+1;changed=true}}if !changed{break}}
  for q in 0..s{next[q]=if cur[q]<inf{cur[q]+1}else{inf}}
  for i in 0..e{if cur[from[i]]<inf{let edit=if label[i]!=a[ts+pos] as u8{1}else{0};let c=cur[from[i]]+edit;if c<next[to[i]]{next[to[i]]=c}}}
  for _ in 0..s-1{let mut changed=false;for i in 0..e{if next[from[i]]<inf&&next[from[i]]+1<next[to[i]]{next[to[i]]=next[from[i]]+1;changed=true}}if !changed{break}}
  unsafe{*out.add(pos)=u8::from(next[accept]<=k)};cur=next;
 }
 t as i64
}
