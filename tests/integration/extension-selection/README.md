# Integration Harness – Extension Selection

1. Build the SPK via `make arch-geminilake-7.2`.
2. Copy to the DS920+ and install with `synopkg install`.
3. Use the helper scripts in this folder (to be added) to drive wizard variables or call the DSM REST endpoints.
4. Verify `php -m` matches expectations and capture logs in `/var/log/php83-extension-selection.log`.
