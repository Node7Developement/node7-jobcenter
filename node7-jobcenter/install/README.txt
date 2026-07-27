NODE7 JOBCENTER CORE JOB FILES

The job center does NOT replace or edit node7-core.

Runtime behavior:
- node7-jobcenter uses exports['node7-core']:AddJob(...) to register only missing public jobs.
- Existing core jobs are never overwritten.
- Law and medic jobs are ignored by the public employment board.

Permanent installation:
1. Back up node7-core/shared/jobs.lua.
2. Replace it with install/jobs.lua from this package.
3. Restart node7-core and node7-jobcenter.

install/jobs.lua is your uploaded jobs.lua with the ten public job definitions appended.
install/public_jobs.lua contains only the public job table for manual merging.
