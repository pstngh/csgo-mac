// Apple Silicon always provides NEON. This build maps the engine's SSE and
// SSE2 intrinsics onto NEON through sse2neon; MMX and 3DNow remain disabled.
bool CheckMMXTechnology( void ) { return false; }
bool CheckSSETechnology( void ) { return true; }
bool CheckSSE2Technology( void ) { return true; }
bool Check3DNowTechnology( void ) { return false; }
