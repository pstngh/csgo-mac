#pragma once

// Source SDK code historically includes the glibc-style <malloc.h> name.
// Darwin publishes the corresponding declarations under <malloc/malloc.h>.
#include <stdlib.h>
#include <malloc/malloc.h>
