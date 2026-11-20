// Clean-room bounded deterministic Sequitur grammar profile.
module sequitur_grammar_induction

struct Grammar {
mut:
    symbols [16384]int
    lengths [256]int
    live [256]bool
    next_rule int
}
struct Duplicate { found bool; r1 int; p1 int; r2 int; p2 int; left int; right int }

fn replace_pair(mut g &Grammar, rule int, position int, token int) {
    for i in position+2 .. g.lengths[rule] { g.symbols[rule*64+i-1]=g.symbols[rule*64+i] }
    g.lengths[rule]--
    g.symbols[rule*64+position]=token
}

fn find_duplicate(g &Grammar) Duplicate {
    for r1 in 0 .. g.next_rule {
        if !g.live[r1] { continue }
        if g.lengths[r1] < 2 { continue }
        for p1 in 0 .. g.lengths[r1]-1 {
            left:=g.symbols[r1*64+p1];right:=g.symbols[r1*64+p1+1]
            for r2 in r1 .. g.next_rule {
                if !g.live[r2] { continue }
                mut start:=0
                if r2==r1 {start=p1+2}
                if g.lengths[r2] < start+2 { continue }
                for p2 in start .. g.lengths[r2]-1 {
                    if g.symbols[r2*64+p2]==left && g.symbols[r2*64+p2+1]==right {
                        return Duplicate{true,r1,p1,r2,p2,left,right}
                    }
                }
            }
        }
    }
    return Duplicate{}
}

fn cleanup_one(mut g &Grammar) bool {
    for target in 1 .. g.next_rule {
        if !g.live[target] {continue}
        mut count:=0;mut parent:=0;mut position:=0
        token:=256+target
        for rule in 0 .. g.next_rule {
            if g.live[rule] {
                for i in 0 .. g.lengths[rule] {
                    if g.symbols[rule*64+i]==token {count++;parent=rule;position=i}
                }
            }
        }
        if count==0 {g.live[target]=false;g.lengths[target]=0;return true}
        if count==1 {
            mut copy:=[64]int{}
            replacement_length:=g.lengths[target]
            for i in 0 .. replacement_length {copy[i]=g.symbols[target*64+i]}
            delta:=replacement_length-1
            old_length:=g.lengths[parent]
            mut i:=old_length-1
            for i>position {g.symbols[parent*64+i+delta]=g.symbols[parent*64+i];i--}
            for i in 0 .. replacement_length {g.symbols[parent*64+position+i]=copy[i]}
            g.lengths[parent]+=delta;g.live[target]=false;g.lengths[target]=0
            return true
        }
    }
    return false
}

fn normalize(mut g &Grammar) {
    for {
        for cleanup_one(mut g) {}
        d:=find_duplicate(g)
        if !d.found {return}
        mut existing:=-1
        for rule in 1 .. g.next_rule {
            if g.live[rule] && g.lengths[rule]==2 && g.symbols[rule*64]==d.left && g.symbols[rule*64+1]==d.right {existing=rule;break}
        }
        if existing>=0 {
            mut rule:=d.r1;mut position:=d.p1
            if rule==existing && position==0 {rule=d.r2;position=d.p2}
            replace_pair(mut g,rule,position,256+existing)
        } else {
            fresh:=g.next_rule;g.next_rule++;g.live[fresh]=true;g.lengths[fresh]=2
            g.symbols[fresh*64]=d.left;g.symbols[fresh*64+1]=d.right
            replace_pair(mut g,d.r2,d.p2,256+fresh)
            replace_pair(mut g,d.r1,d.p1,256+fresh)
        }
    }
}

@[export: 'sequitur_grammar_induction']
pub fn sequitur_grammar_induction(input &i64, length usize) i64 {
    unsafe {
        if input==nil || length<1 || length>66 {return -1}
        if input[0]<0 || input[0]>64 || length!=usize(input[0])+1 {return -1}
        n:=int(input[0])
        for i in 0 .. n {if input[i+1]<0 || input[i+1]>255 {return -1}}
        mut g:=Grammar{}
        g.live[0]=true;g.next_rule=1
        for i in 0 .. n {g.symbols[g.lengths[0]]=int(input[i+1]);g.lengths[0]++;normalize(mut g)}
        mut rules:=i64(0);mut symbols:=i64(0)
        for rule in 0 .. g.next_rule {if g.live[rule] {if rule!=0 {rules++};symbols+=i64(g.lengths[rule])}}
        return 1000*rules+symbols
    }
}
