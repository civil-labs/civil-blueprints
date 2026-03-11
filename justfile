set shell := ["pwsh.exe", "-c"]

install:
    go install github.com/bufbuild/buf/cmd/buf@latest
    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
    go install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest

    go get google.golang.org/protobuf
    go get connectrpc.com/connect
    
    # Clean old vendor folder safely
    if (Test-Path vendor) { Remove-Item -Recurse -Force vendor -ErrorAction Ignore }
    
    # 2. Clone full repo into a temporary subfolder
    # We use --depth 1 to avoid downloading the entire git history (saves time/bandwidth)
    git clone --depth 1 https://github.com/bufbuild/protovalidate.git vendor/temp

    # 4. Move the specific 'buf' directory we need
    # Source: vendor/temp/proto/protovalidate/buf
    # Dest:   vendor/buf
    Move-Item -Path vendor/temp/proto/protovalidate -Destination vendor/protovalidate

    # 5. Cleanup: Delete the temporary clone
    Remove-Item -Recurse -Force vendor/temp -ErrorAction Ignore

generate:
    # Clean old generated code
    if (Test-Path gen) { Remove-Item -Recurse -Force -ErrorAction SilentlyContinue gen/go, gen/es }

    # Create directories (New-Item -Force acts like mkdir -p)
    New-Item -ItemType Directory -Force -Path gen/go, gen/es | Out-Null

    # Run Protoc
    # Note: We use Get-ChildItem to find .proto files recursively
    # We point -I to the deep folder inside the vendored repo so imports resolve correctly
    protoc \
        -I proto \
        -I vendor/protovalidate \
        --go_out=gen/go --go_opt=paths=source_relative \
        --connect-go_out=gen/go --connect-go_opt=paths=source_relative \
        (Get-ChildItem -Path proto -Recurse -Filter *.proto).FullName