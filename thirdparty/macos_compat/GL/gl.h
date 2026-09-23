#pragma once
#include <OpenGL/gl.h>

// The Linux GL headers expose these calling-convention macros. Darwin uses
// the platform C ABI and omits APIENTRY, but TOGL includes it in function
// pointer type declarations.
#ifndef APIENTRY
#define APIENTRY
#endif
#ifndef GLAPIENTRY
#define GLAPIENTRY
#endif
