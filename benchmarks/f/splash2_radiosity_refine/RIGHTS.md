# Rights and provenance

The package ports are new clean-room implementations. No SPLASH-2 source code, comments, constants, input data, source implementation text, or problem text were copied or adapted.

The inspected SPLASH-2 Radiosity source file carries a Stanford University 1994 notice. The mirror's top-level documentation does not state a general software license. The inspected source-file notice permits using, copying, and modifying that software for non-commercial purposes while retaining the notice, but forbids other uses, including redistribution of the original software in whole or in part, without prior written permission. No redistribution right for the upstream software is assumed. This package does not include upstream source, and it does not rely on that source license to distribute these newly written ports.

The implementation follows the published algorithm description of adaptive hierarchical form-factor subdivision, narrowed to one bounded pair of parallel square patches with centroid samples and a specified refinement probe. The coarse-versus-next-quadrant difference used here is a heuristic for this profile; it is not a certified error bound and does not reproduce the paper's precision guarantee. The profile does not reproduce the SPLASH-2 scene, visibility system, iterative radiosity solver, runtime, or program behavior.

## References

- Pat Hanrahan, David Salzman, and Larry Aupperle, “A Rapid Hierarchical Radiosity Algorithm,” *Proceedings of SIGGRAPH 1991*, pp. 197–206. [ACM DOI](https://doi.org/10.1145/122718.122740).
- Steven Cameron Woo, Moriyoshi Ohara, Evan Torrie, Jaswinder Pal Singh, and Anoop Gupta, “The SPLASH-2 Programs: Characterization and Methodological Considerations,” ISCA 1995. [Paper PDF](https://pages.cs.wisc.edu/~markhill/restricted/isca95_splash2.pdf).
- [SPLASH-2 Radiosity source file](https://github.com/staceyson/splash2/blob/master/codes/apps/radiosity/rad_main.C), inspected only for source identity and licensing terms.
- [SPLASH-2 Radiosity README](https://github.com/staceyson/splash2/blob/master/codes/apps/radiosity/README.radiosity), inspected only for algorithm references and application scope.
