# NODE7 Job Center Recipe

1. Copy `node7-jobcenter` to `resources/[node7]/node7-jobcenter`.
2. Keep `node7-core` and `node7-interaction` started before the job center.
3. The job center registers missing public jobs at runtime through the core `AddJob` export.
4. For permanent shared jobs, copy `install/jobs.lua` to `node7-core/shared/jobs.lua` after backing up the existing file.

```cfg
ensure node7-core
ensure node7-interaction
ensure node7-jobcenter
```
