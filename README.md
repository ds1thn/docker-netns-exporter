# docker-netns-exporter
Number of TCP connections in a given state inside the Docker container's network namespace

## How to use
    docker-сompose up -d

# Prometheus
```yaml
  - job_name: "docker-netsh"
    dockerswarm_sd_configs:
      - host: unix:///var/run/docker.sock
        role: tasks
    relabel_configs:
      - source_labels: [__meta_dockerswarm_task_desired_state]
        regex: running
        action: keep
      - source_labels: [__meta_dockerswarm_service_name]
        regex: docker-netsh-exporter_app
        action: keep
      - source_labels: [__meta_dockerswarm_network_name]
        regex: my_network
        action: keep
      - source_labels: [__meta_dockerswarm_service_name]
        target_label: job
      - source_labels: [__meta_dockerswarm_node_hostname]
        target_label: instance
```
