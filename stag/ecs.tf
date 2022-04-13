resource "aws_ecs_cluster" "web-cluster" {
  name               = var.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.test.name]
  tags = {
    "env"       = "stag"
    "createdBy" = "robinder"
  }
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  #depends_on = [ aws_autoscaling_group.asg]

  provisioner "local-exec" {
    when = destroy

    command = <<CMD
    # # Get the list of capacity providers associated with this cluster
     CAP_PROVS="$(aws ecs describe-clusters --clusters "${self.arn}" \
        --query 'clusters[*].capacityProviders[*]' --output text)"

     #  Now get the list of autoscaling groups from those capacity providers
      ASG_ARNS="$(aws ecs describe-capacity-providers \
        --capacity-providers "$CAP_PROVS" \
        --query 'capacityProviders[*].autoScalingGroupProvider.autoScalingGroupArn' \
        --output text)"

      if [ -n "$ASG_ARNS" ] && [ "$ASG_ARNS" != "None" ]
      then
        for ASG_ARN in $ASG_ARNS
        do
        ASG_NAME=$(echo $ASG_ARN | cut -d/ -f2-)

          # Set the autoscaling group size to zero
          aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name "$ASG_NAME" \
            --min-size 0 --max-size 0 --desired-capacity 0

          # Remove scale-in protection from all instances in the asg
          #INSTANCES="$(aws autoscaling describe-auto-scaling-groups \
           # --auto-scaling-group-names "$ASG_NAME" \
           # --query 'AutoScalingGroups[*].Instances[*].InstanceId' \
           # --output text)"
          #aws autoscaling set-instance-protection --instance-ids $INSTANCES \
           # --auto-scaling-group-name "$ASG_NAME" \
           # --no-protected-from-scale-in
        done
      fi
CMD
  }
}

resource "aws_ecs_capacity_provider" "test" {
  name = "capacity-provider-stag"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.asg.arn
    #  managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100

    }
  }
  #depends_on = [ aws_autoscaling_group.asg]
}

# update file container-def, so it's pulling image from ecr
resource "aws_ecs_task_definition" "task-definition-test" {
  family                = "gravystack-stag"
  container_definitions = file("container-definitions/container-def.json")
  network_mode          = "bridge"
  tags = {
    "env"       = "stag"
    "createdBy" = "robinder"
  }
}

resource "aws_ecs_service" "service" {
  name            = "gravystack-stag"
  cluster         = aws_ecs_cluster.web-cluster.id
  task_definition = aws_ecs_task_definition.task-definition-test.arn
  desired_count   = 2

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.test.name
    weight            = 1

  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "gravystack-stag"
    container_port   = 3000
  }
  # Optional: Allow external changes without Terraform plan difference(for example ASG)
  # lifecycle {
  #  ignore_changes = [desired_count]
  # }
  #launch_type = "EC2"
  #depends_on  = [aws_lb_listener.web-listener]
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 6
  min_capacity       = 2
  resource_id        = "service/gravystack-stag/gravystack-stag"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "gravystack_memory_in" {
  name               = "stag-to-memory-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 40
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "gravystack_cpu_in" {
  name               = "stag-to-cpu-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 40
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}
resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/gravystack-stag"
  tags = {
    "env"       = "stag"
    "createdBy" = "robinder"
  }
}




