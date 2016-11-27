# ELB Health Check

AWS elastic load balancers and application load balancers are awesome, but their health checks are pretty dumb. It's not possible to specify any headers (such as the Host header), making it impossible for virtual hosts to be taken into account when determining if the host is healthy or not.

## What problems does this library intend to solve?

* A health check pinging the default virtualhost is no indication of whether or not your app is up or down
* You have multiple applications that all must be up for the ELB/ALB to consider your host healthy
* Hitting port 80 with default ELB health checks triggers a 301 redirect to HTTPS even though HTTPS is terminated at the ELB :facepalm:

## How do I use this?

Set a `HEALTH_CHECK_HOSTNAMES` environment variable that contains a comma separated list of hostnames that should be checked as part of each health check.

Add a `/health_check` endpoint in each application that returns any `20x` status code in response to a `HEAD` request when it should be considered healthy. Returning a `204 No Content` is recommended, as the response body is always ignored.

Clone this repo, run `bundle install`, and run `bundle exec rackup`.

[Point ELB's health checker](http://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html) at the port where this Rack application is running and

## Caveats

* If you have multiple apps and _any_ app fails to return a `20x` status code, the entire node will be considered unhealthy. So if two unrelated apps are running on the same server behind the same load balancer and one gets hit with a bad deploy that breaks the `/health_check` endpoint, the entire node will be taken out of service.
* Requests to applications are made concurrently to keep things as quick as possible, but if you have oodles of applications running on a server, this may time out before it's able to respond to ELB. You can tune the `HealthCheckTimeoutSeconds` setting if necessary.
* If your application spawns processes from the first request after a timeout, keep in mind this is going to hit all the apps at the same time, which could cause load spikes and/or timeouts.
* You better monitor this process and make sure it stays running! If it isn't running, your health check is going to fail and the node will be taken out of service.

## Copyright

&copy; 2016 James Miller
