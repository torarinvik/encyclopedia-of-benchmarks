# Rights and provenance

The implementation is a clean-room benchmark profile based on published
algorithmic ideas. The primary method is Shanmugavelayutham Muthukrishnan,
“Efficient Algorithms for Document Retrieval Problems,” SODA 2002,
[DOI 10.1145/545381.545469](https://doi.org/10.1145/545381.545469), with book
context from Sharma V. Thankachan, *Encyclopedia of Algorithms*, Chapter 629,
[DOI 10.1007/978-1-4939-2864-4_629](https://doi.org/10.1007/978-1-4939-2864-4_629).
The `DA`/previous-occurrence/RMQ method is independently summarized in
Navarro and Mäkinen, [“Compressed Full-Text Indexes”](https://doi.org/10.1145/1216370.1216372).

Only the algorithmic method and public problem definitions are used. The
bounded contract, source code, port structure, references, deterministic
leftmost tie rule, byte output format, workload cases, and metadata were
written independently. No upstream code, prose, fixtures, or tests are
included.
