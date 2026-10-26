module approximate_regex_matching

// Layered edit-distance shortest paths over a supplied literal NFA.
@[export: 'approximate_regex_matching']
pub fn approximate_regex_matching(x &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if length < 6 || length > 66 { return -1 }
        sv:=x[0];ev:=x[1];tv:=x[2];kv:=x[3];startv:=x[4];acceptv:=x[5]
        if sv<2||sv>8||ev<1||ev>16||tv<0||tv>12||kv<0||kv>3||startv<0||acceptv<0||startv>=sv||acceptv>=sv||startv==acceptv{return -1}
        s:=int(sv);e:=int(ev);t:=int(tv);k:=int(kv);start:=int(startv);accept:=int(acceptv);ts:=6+3*e
        if int(length)!=ts+t{return -1}
        mut from:=[16]int{};mut to:=[16]int{};mut label:=[16]u8{}
        for i:=0;i<e;i++ {u:=x[6+3*i];v:=x[7+3*i];ch:=x[8+3*i]
            if u<0||u>=sv||v<0||v>=sv||ch<1||ch>127{return -1}
            from[i]=int(u);to[i]=int(v);label[i]=u8(ch)
            for j:=0;j<i;j++ {if from[i]==from[j]&&to[i]==to[j]&&label[i]==label[j]{return -1}}
        }
        for i:=0;i<t;i++ {if x[ts+i]<1||x[ts+i]>127{return -1}}
        if capacity<t||(t>0&&output==nil){return -2}
        inf:=k+1;mut cur:=[8]int{};mut next:=[8]int{}
        for q:=0;q<s;q++ {cur[q]=inf}
        for pos:=0;pos<t;pos++ {
            cur[start]=0
            for _:=0;_<s-1;_++ {mut changed:=false
                for i:=0;i<e;i++ {if cur[from[i]]<inf&&cur[from[i]]+1<cur[to[i]] {cur[to[i]]=cur[from[i]]+1;changed=true}}
                if !changed {break}
            }
            for q:=0;q<s;q++ {if cur[q]<inf {next[q]=cur[q]+1}else{next[q]=inf}}
            for i:=0;i<e;i++ {if cur[from[i]]<inf {mut cost:=cur[from[i]];if label[i]!=u8(x[ts+pos]){cost++};if cost<next[to[i]]{next[to[i]]=cost}}}
            for _:=0;_<s-1;_++ {mut changed:=false
                for i:=0;i<e;i++ {if next[from[i]]<inf&&next[from[i]]+1<next[to[i]] {next[to[i]]=next[from[i]]+1;changed=true}}
                if !changed {break}
            }
            if next[accept]<=k {output[pos]=1}else{output[pos]=0}
            for q:=0;q<s;q++ {cur[q]=next[q]}
        }
        return i64(t)
    }
}
