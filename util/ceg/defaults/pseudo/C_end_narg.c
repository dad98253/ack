#include <assert.h>

extern int locals_created; 

C_end_narg()
{
	assert( locals_created);
}
