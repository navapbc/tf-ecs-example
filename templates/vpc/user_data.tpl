#!/bin/bash

# ref: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/start_task_at_launch.html
# Write the cluster configuration variable to the ecs.config file
# (add any other configuration variables here also)
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_LOGLEVEL=debug >> /etc/ecs/ecs.config
