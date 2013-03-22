worker_processes 12
timeout 10
preload_app true

Rainbows! do
    use :EventMachine
    worker_connections 1000
    client_max_body_size nil
    keepalive_timeout 0
end