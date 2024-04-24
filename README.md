# Smoke QA

Define rules to catch web regressions on platforms using YAML configuration files.

## Requirements

* Ruby
* Bundler

## Getting started

1. Install dependencies

```shell
  bundle install
```

2. Define a configuration file

_Example: QRCODE generator app_
Create a new file `conf/qrcode.yml`

Open file

```
# conf/qrcode.yml

instances:
  - name: QRCODE Supcode (PROD)
    url: https://qrcode.supcode.fr/
    request:
      status: 200
      max_request_time: 1.0
    features:
      - name: Link to source code
        required: true
        expected: "Code source sur Github"
      - name: Implements Web Assembly program
        required: true
        expected: "WebAssembly.instantiateStreaming(fetch("main.wasm"), go.importObject)"
      - name: Invalid rule
        required: true
        expected: "Text that does not exist"
```

3. Run script `ruby main`