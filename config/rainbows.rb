worker_processes 4
timeout 10
preload_app true

Rainbows! do
    use :EventMachine
    worker_connections 400
    client_max_body_size nil
    keepalive_timeout 0
end