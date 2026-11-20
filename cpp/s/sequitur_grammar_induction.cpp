// Clean-room bounded deterministic Sequitur grammar profile.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kRuleCapacity = 256;
constexpr int kSymbolCapacity = 64;
constexpr int kNonterminalBase = 256;
struct Grammar {
    std::array<std::array<std::int32_t, kSymbolCapacity>, kRuleCapacity> symbols{};
    std::array<int, kRuleCapacity> length{};
    std::array<bool, kRuleCapacity> live{};
    int next_rule = 1;
};
struct Duplicate { bool found = false; int r1=0, p1=0, r2=0, p2=0, left=0, right=0; };

void replace_pair(Grammar& g, int rule, int position, int token) {
    for (int i = position + 2; i < g.length[rule]; ++i) g.symbols[rule][i-1] = g.symbols[rule][i];
    --g.length[rule]; g.symbols[rule][position] = token;
}

Duplicate find_duplicate(const Grammar& g) {
    for (int r1=0; r1<g.next_rule; ++r1) if (g.live[r1]) {
        for (int p1=0; p1+1<g.length[r1]; ++p1) {
            const int left=g.symbols[r1][p1], right=g.symbols[r1][p1+1];
            for (int r2=r1; r2<g.next_rule; ++r2) if (g.live[r2]) {
                const int start = r2==r1 ? p1+2 : 0;
                for (int p2=start; p2+1<g.length[r2]; ++p2) {
                    if (g.symbols[r2][p2]==left && g.symbols[r2][p2+1]==right)
                        return {true,r1,p1,r2,p2,left,right};
                }
            }
        }
    }
    return {};
}

bool cleanup_one(Grammar& g) {
    for (int target=1; target<g.next_rule; ++target) if (g.live[target]) {
        int count=0, parent=-1, position=-1; const int token=kNonterminalBase+target;
        for (int rule=0; rule<g.next_rule; ++rule) if (g.live[rule])
            for (int i=0; i<g.length[rule]; ++i) if (g.symbols[rule][i]==token) { ++count; parent=rule; position=i; }
        if (count==0) { g.live[target]=false; g.length[target]=0; return true; }
        if (count==1) {
            std::array<int,kSymbolCapacity> copy{}; const int replacement_length=g.length[target];
            for (int i=0;i<replacement_length;++i) copy[i]=g.symbols[target][i];
            const int delta=replacement_length-1, old_length=g.length[parent];
            for (int i=old_length-1;i>position;--i) g.symbols[parent][i+delta]=g.symbols[parent][i];
            for (int i=0;i<replacement_length;++i) g.symbols[parent][position+i]=copy[i];
            g.length[parent]+=delta; g.live[target]=false; g.length[target]=0; return true;
        }
    }
    return false;
}

void normalize(Grammar& g) {
    for (;;) {
        while (cleanup_one(g)) {}
        const Duplicate d=find_duplicate(g); if (!d.found) return;
        int existing=-1;
        for (int rule=1;rule<g.next_rule;++rule)
            if (g.live[rule] && g.length[rule]==2 && g.symbols[rule][0]==d.left && g.symbols[rule][1]==d.right) { existing=rule; break; }
        if (existing>=0) {
            int rule=d.r1, position=d.p1;
            if (rule==existing && position==0) { rule=d.r2; position=d.p2; }
            replace_pair(g,rule,position,kNonterminalBase+existing);
        } else {
            const int fresh=g.next_rule++;
            g.live[fresh]=true; g.length[fresh]=2; g.symbols[fresh][0]=d.left; g.symbols[fresh][1]=d.right;
            replace_pair(g,d.r2,d.p2,kNonterminalBase+fresh);
            replace_pair(g,d.r1,d.p1,kNonterminalBase+fresh);
        }
    }
}
}

extern "C" std::int64_t sequitur_grammar_induction(const std::int64_t* input, std::size_t length) {
    if (!input || length<1 || length>66 || input[0]<0 || input[0]>64 || length!=static_cast<std::size_t>(input[0])+1) return -1;
    const int n=static_cast<int>(input[0]);
    for (int i=0;i<n;++i) if (input[i+1]<0 || input[i+1]>255) return -1;
    Grammar g{}; g.live[0]=true;
    for (int i=0;i<n;++i) { g.symbols[0][g.length[0]++]=static_cast<int>(input[i+1]); normalize(g); }
    int rules=0, symbols=0;
    for (int rule=0;rule<g.next_rule;++rule) if (g.live[rule]) { if (rule!=0) ++rules; symbols+=g.length[rule]; }
    return static_cast<std::int64_t>(1000)*rules+symbols;
}
