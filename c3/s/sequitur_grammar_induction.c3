// Clean-room bounded deterministic Sequitur grammar profile.
module sequitur_grammar_induction;
const int RULES = 256, WIDTH = 64, NT_BASE = 256;
struct Grammar { int[16384] symbols; int[256] lengths; bool[256] live; int next_rule; }
struct Duplicate { bool found; int r1; int p1; int r2; int p2; int left; int right; }

fn void replace_pair(Grammar* g, int rule, int position, int token) {
    for (int i=position+2; i<g.lengths[rule]; i++) g.symbols[rule*WIDTH+i-1]=g.symbols[rule*WIDTH+i];
    g.lengths[rule]--;
    g.symbols[rule*WIDTH+position]=token;
}
fn Duplicate find_duplicate(Grammar* g) {
    for (int r1=0; r1<g.next_rule; r1++) if (g.live[r1]) {
        for (int p1=0; p1+1<g.lengths[r1]; p1++) {
            int left=g.symbols[r1*WIDTH+p1], right=g.symbols[r1*WIDTH+p1+1];
            for (int r2=r1; r2<g.next_rule; r2++) if (g.live[r2]) {
                int start=r2==r1 ? p1+2 : 0;
                for (int p2=start; p2+1<g.lengths[r2]; p2++)
                    if (g.symbols[r2*WIDTH+p2]==left && g.symbols[r2*WIDTH+p2+1]==right)
                        return {true,r1,p1,r2,p2,left,right};
            }
        }
    }
    return {false,0,0,0,0,0,0};
}
fn bool cleanup_one(Grammar* g) {
    for (int target=1; target<g.next_rule; target++) if (g.live[target]) {
        int count=0, parent=0, position=0, token=NT_BASE+target;
        for (int rule=0; rule<g.next_rule; rule++) if (g.live[rule])
            for (int i=0; i<g.lengths[rule]; i++) if (g.symbols[rule*WIDTH+i]==token) {count++;parent=rule;position=i;}
        if (count==0) {g.live[target]=false;g.lengths[target]=0;return true;}
        if (count==1) {
            int[64] copy={}; int replacement_length=g.lengths[target];
            for (int i=0;i<replacement_length;i++) copy[i]=g.symbols[target*WIDTH+i];
            int delta=replacement_length-1, old_length=g.lengths[parent];
            for (int i=old_length-1;i>position;i--) g.symbols[parent*WIDTH+i+delta]=g.symbols[parent*WIDTH+i];
            for (int i=0;i<replacement_length;i++) g.symbols[parent*WIDTH+position+i]=copy[i];
            g.lengths[parent]+=delta;g.live[target]=false;g.lengths[target]=0;return true;
        }
    }
    return false;
}
fn void normalize(Grammar* g) {
    while (true) {
        while (cleanup_one(g)) {}
        Duplicate d=find_duplicate(g); if (!d.found) return;
        int existing=-1;
        for (int r=1;r<g.next_rule;r++) if (g.live[r]&&g.lengths[r]==2&&g.symbols[r*WIDTH]==d.left&&g.symbols[r*WIDTH+1]==d.right) {existing=r;break;}
        if (existing>=0) {
            int rule=d.r1, position=d.p1;
            if (rule==existing&&position==0) {rule=d.r2;position=d.p2;}
            replace_pair(g,rule,position,NT_BASE+existing);
        } else {
            int fresh=g.next_rule++;g.live[fresh]=true;g.lengths[fresh]=2;
            g.symbols[fresh*WIDTH]=d.left;g.symbols[fresh*WIDTH+1]=d.right;
            replace_pair(g,d.r2,d.p2,NT_BASE+fresh);replace_pair(g,d.r1,d.p1,NT_BASE+fresh);
        }
    }
}

fn long sequitur_grammar_induction(long* input, usz length) @export("sequitur_grammar_induction") {
    if (input==null||length<1||length>66) return -1;
    if (input[0]<0||input[0]>64||length!=(usz)input[0]+1) return -1;
    int n=(int)input[0];for(int i=0;i<n;i++)if(input[i+1]<0||input[i+1]>255)return -1;
    Grammar g={};g.live[0]=true;g.next_rule=1;
    for(int i=0;i<n;i++){g.symbols[g.lengths[0]++]=(int)input[i+1];normalize(&g);}
    long rules=0,symbols=0;
    for(int r=0;r<g.next_rule;r++)if(g.live[r]){if(r!=0)rules++;symbols+=g.lengths[r];}
    return 1000*rules+symbols;
}
