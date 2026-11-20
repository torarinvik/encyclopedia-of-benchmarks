# Rights and provenance

The benchmark implements the behavior of Lawrence Philips's Double Metaphone
algorithm as described in the June 2000 article and embodied in the 1998/1999
source archive. The article and source are cited for algorithm provenance. The
archived C++ file carries a Philips copyright notice; no license for that
original source was identified. This package does not reproduce its source
text, comments, code structure, or test cases.

Apache Commons Codec publishes a separate full implementation under the
Apache License 2.0 and cites Philips's article and source. It is used only as a
behavior cross-check. No Apache implementation text, code structure, or test
fixtures are reused. Fresh fixtures are supplied in `workload.json`.

References:

- Lawrence Philips, [“The Double Metaphone Search Algorithm,” C/C++ Users
  Journal, June 2000](https://jacobfilipp.com/DrDobbs/articles/CUJ/2000/0006/philips/philips.htm)
- Philips, [original Double Metaphone C++ source archive / source mirror](https://raw.githubusercontent.com/nickgammon/mushclient/master/Dmetaph.cpp)
- [NIST DADS: Double Metaphone](https://xlinux.nist.gov/dads/HTML/doubleMetaphone.html)
- [Apache Commons Codec: DoubleMetaphone source](https://commons.apache.org/proper/commons-codec/apidocs/src-html/org/apache/commons/codec/language/DoubleMetaphone.html)
- [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)
