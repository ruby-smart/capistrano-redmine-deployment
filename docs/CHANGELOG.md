# Capistrano::Redmine::Deployment - CHANGELOG

## [1.1.0] - 2026-07-10
* **[add]** ENV layer for config (`REDMINE_API_KEY`, `REDMINE_HOST`, `REDMINE_PROJECT`, `REDMINE_REPOSITORY`, `REDMINE_CA_FILE`)
* **[add]** `:redmine_api_key` capistrano variable, with `:redmine_api_key_command` (command stdout, e.g. macOS keychain) as fallback
* **[add]** `:redmine_ca_file` config (and `REDMINE_CA_FILE` ENV) as a safe alternative to disabling host verification
* **[add]** rspec test suite for `Config.resolve` layer precedence
* **[ref]** config resolution order: capistrano is the base, then `.redmine` files, then ENV win over it
* **[fix]** enable SSL by URI scheme (`https`) instead of only port 443, so HTTPS on non-standard ports works

## [1.0.1] - 2025-10-24
* **[add]** config for `host_verification` to skip issues with OpenSSL / CRL issues
* **[add]** warning message during deployment while host verification is disabled
* **[ref]** setup task for better configuration
* **[ref]** logging messages for successfully / error deployment
* **[fix]** host verification SSL/CRL issues

## [1.0.0] - 2024-10-01
* **[add]** config, client & receipts
* **[add]** rake task for setup
* **[add]** railties setup task
* **[fix]** deployment bugs

## [0.1.0] - 2024-09-29
* Initial commit
* docs, version, structure
