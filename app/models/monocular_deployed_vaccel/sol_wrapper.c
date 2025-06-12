#include "sol_monocular.h"
#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <vaccel.h>

extern "C"
{

int sol_monocular_init_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 0);
	assert(nr_out == 0);

	sol_monocular_init();

	return 0;
}

int sol_predict_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 2);
	assert(nr_out == 1);

	sol_f32 *in__input_1 = (sol_f32 *)vaccel_extract_serial_arg(read, 0);
	sol_s64 *vdims = (sol_s64 *)vaccel_extract_serial_arg(read, 1);
	sol_f32 *out__0 = (sol_f32 *)vaccel_extract_serial_arg(write, 0);

	sol_predict(in__input_1, out__0, vdims);

	vaccel_write_serial_arg(write, 0, out__0);

	return 0;
}

int sol_monocular_set_IO_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 2);
	assert(nr_out == 1);

	sol_f32 *in__input_1 = (sol_f32 *)vaccel_extract_serial_arg(read, 0);
	sol_s64 *vdims = (sol_s64 *)vaccel_extract_serial_arg(read, 1);
	sol_f32 *out__0 = (sol_f32 *)vaccel_extract_serial_arg(write, 0);

	sol_monocular_set_IO(in__input_1, out__0, vdims);

	vaccel_write_serial_arg(write, 0, out__0);

	return 0;
}

int sol_monocular_run_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 0);
	assert(nr_out == 0);

	sol_monocular_run();

	return 0;
}

int sol_monocular_optimize_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 1);
	assert(nr_out == 0);

	int *level = (int *)vaccel_extract_serial_arg(read, 0);

	sol_monocular_optimize(*level);

	return 0;
}

int sol_monocular_sync_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 0);
	assert(nr_out == 0);

	sol_monocular_sync();

	return 0;
}

int sol_monocular_get_output_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 0);
	assert(nr_out == 0);

	sol_monocular_get_output();

	return 0;
}

int sol_monocular_free_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 0);
	assert(nr_out == 0);

	sol_monocular_free();

	return 0;
}

int sol_monocular_free_host_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 0);
	assert(nr_out == 0);

	sol_monocular_free_host();

	return 0;
}

int sol_monocular_free_device_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 0);
	assert(nr_out == 0);

	sol_monocular_free_device();

	return 0;
}

int sol_monocular_free_IO_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 0);
	assert(nr_out == 0);

	sol_monocular_free_IO();

	return 0;
}

int sol_monocular_set_seed_unpack(struct vaccel_arg *read, size_t nr_in,
	       struct vaccel_arg *write, size_t nr_out)
{
	assert(nr_in == 1);
	assert(nr_out == 0);

	int64_t *seed = (int64_t *)vaccel_extract_serial_arg(read, 0);

	sol_monocular_set_seed(*seed);

	return 0;
}

}
